# Data Isolation Patterns for Modular Monoliths

## Overview

Each module in a modular monolith should own its data to prevent tight coupling at the database level. This guide covers patterns for data isolation while sharing a single database.

## Core Principle

**Each module has its own DbContext that only knows about its entities.** Modules cannot share tables or create foreign keys to each other's tables.

## Separate DbContext Per Module

### Basic Setup

```csharp
// Ordering.Infrastructure/Persistence/OrderingDbContext.cs
public class OrderingDbContext : DbContext
{
    public DbSet<Order> Orders { get; set; }
    public DbSet<OrderItem> OrderItems { get; set; }

    public OrderingDbContext(DbContextOptions<OrderingDbContext> options)
        : base(options) { }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        // Only configure Ordering entities
        builder.ApplyConfigurationsFromAssembly(
            typeof(OrderingDbContext).Assembly,
            type => type.Namespace?.Contains("Ordering") == true);

        // Use schema for table grouping
        builder.HasDefaultSchema("ordering");
    }
}

// Inventory.Infrastructure/Persistence/InventoryDbContext.cs
public class InventoryDbContext : DbContext
{
    public DbSet<Product> Products { get; set; }
    public DbSet<StockLevel> StockLevels { get; set; }

    public InventoryDbContext(DbContextOptions<InventoryDbContext> options)
        : base(options) { }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        builder.ApplyConfigurationsFromAssembly(
            typeof(InventoryDbContext).Assembly,
            type => type.Namespace?.Contains("Inventory") == true);

        builder.HasDefaultSchema("inventory");
    }
}
```

### Registration

```csharp
// Program.cs or Module Registration
services.AddDbContext<OrderingDbContext>(options =>
    options.UseNpgsql(connectionString));

services.AddDbContext<InventoryDbContext>(options =>
    options.UseNpgsql(connectionString));  // Same connection string
```

## Schema Separation

### Using Database Schemas

Group each module's tables under a schema:

```csharp
protected override void OnModelCreating(ModelBuilder builder)
{
    builder.HasDefaultSchema("ordering");

    builder.Entity<Order>().ToTable("orders");      // ordering.orders
    builder.Entity<OrderItem>().ToTable("items");   // ordering.items
}
```

### Using Table Prefixes

Alternative if schemas aren't available:

```csharp
builder.Entity<Order>().ToTable("ordering_orders");
builder.Entity<OrderItem>().ToTable("ordering_items");
```

## No Cross-Module Foreign Keys

### The Problem

```csharp
// BAD - Creates tight coupling
public class Order
{
    public Guid CustomerId { get; private set; }
    public Customer Customer { get; private set; }  // ❌ FK to Customer module
}
```

### The Solution: ID as Value Object

```csharp
// GOOD - Use ID without navigation property
public class Order
{
    public Guid Id { get; private set; }
    public CustomerId CustomerId { get; private set; }  // Value object, not FK

    // No navigation property to Customer
}

// Value Object for type safety
public record CustomerId(Guid Value);

// Configuration
builder.Entity<Order>()
    .Property(o => o.CustomerId)
    .HasConversion(
        id => id.Value,
        value => new CustomerId(value));
```

## Data Replication Strategies

### When You Need Data from Another Module

#### Option 1: Query at Runtime (Preferred for Fresh Data)

```csharp
public class CreateShipmentHandler
{
    private readonly IOrderingModuleApi _orderingApi;

    public async Task Handle(CreateShipmentCommand cmd)
    {
        // Query order data when needed
        var order = await _orderingApi.GetOrder(cmd.OrderId);
        // Use order data...
    }
}
```

#### Option 2: Cache Relevant Data (For Performance)

```csharp
// Store denormalized data relevant to this module
public class OrderSummary  // In Shipping module
{
    public Guid OrderId { get; set; }
    public string CustomerName { get; set; }
    public string ShippingAddress { get; set; }
    // Only fields Shipping needs
}

// Update via integration events
public class OrderPlacedHandler : INotificationHandler<OrderPlacedIntegrationEvent>
{
    public async Task Handle(OrderPlacedIntegrationEvent notification, CancellationToken ct)
    {
        var summary = new OrderSummary
        {
            OrderId = notification.OrderId,
            CustomerName = notification.CustomerName,
            ShippingAddress = notification.ShippingAddress
        };
        await _repository.SaveOrderSummary(summary);
    }
}
```

## Eventual Consistency

### Accept Staleness

Cross-module data may be stale. Design for eventual consistency:

```csharp
public class DisplayOrderHandler
{
    public async Task<OrderDisplayDto> Handle(GetOrderDisplayQuery query)
    {
        var order = await _orderRepository.GetById(query.OrderId);

        // Customer data might be slightly stale - that's OK
        var customer = await _customerCache.GetById(order.CustomerId);

        return new OrderDisplayDto
        {
            OrderId = order.Id,
            // Cached customer data
            CustomerName = customer?.Name ?? "Customer",
            CustomerEmail = customer?.Email ?? "N/A"
        };
    }
}
```

### Handle Missing Data Gracefully

```csharp
public class ProductDisplayHandler
{
    public async Task<ProductDto> Handle(GetProductQuery query)
    {
        var product = await _productRepo.GetById(query.ProductId);

        // Inventory data comes from another module
        StockLevel? stock = null;
        try
        {
            stock = await _inventoryApi.GetStockLevel(query.ProductId);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to get stock level for {ProductId}", query.ProductId);
            // Continue without stock info
        }

        return new ProductDto
        {
            Id = product.Id,
            Name = product.Name,
            InStock = stock?.Quantity > 0,
            StockQuantity = stock?.Quantity
        };
    }
}
```

## Migration Strategies

### Module-Specific Migrations

Each module manages its own migrations:

```bash
# Generate migration for Ordering module
dotnet ef migrations add AddOrderStatus \
    --context OrderingDbContext \
    --output-dir Persistence/Migrations

# Generate migration for Inventory module
dotnet ef migrations add AddStockReservations \
    --context InventoryDbContext \
    --output-dir Persistence/Migrations
```

### Migration Order

Apply migrations by module in any order (no cross-references):

```csharp
public static async Task ApplyMigrations(IServiceProvider services)
{
    // Each module's migrations are independent
    using var scope = services.CreateScope();

    var orderingDb = scope.ServiceProvider.GetRequiredService<OrderingDbContext>();
    await orderingDb.Database.MigrateAsync();

    var inventoryDb = scope.ServiceProvider.GetRequiredService<InventoryDbContext>();
    await inventoryDb.Database.MigrateAsync();
}
```

## Query Patterns

### Cross-Module Reporting

For reporting that spans modules, use read-only views or separate reporting database:

```csharp
// Reporting module with read-only access
public class ReportingDbContext : DbContext
{
    public IQueryable<OrderReportView> OrderReports => Set<OrderReportView>().AsNoTracking();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        // Map to database view that joins across schemas
        builder.Entity<OrderReportView>()
            .ToView("order_report_view", "reporting")
            .HasNoKey();
    }
}
```

## Best Practices Summary

1. **One DbContext per module** - Never share DbContext across modules
2. **No navigation properties across modules** - Use IDs only
3. **Schema or prefix for grouping** - Keep tables organized
4. **Independent migrations** - Each module manages its schema
5. **Accept eventual consistency** - Design for stale data
6. **Reporting as separate concern** - Use views or dedicated database

---

**Related:** `module-communication.md`, `ports-adapters-guide.md`
