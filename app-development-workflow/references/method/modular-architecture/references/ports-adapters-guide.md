# Ports and Adapters (Hexagonal) Architecture Guide

## Overview

Ports and Adapters (also called Hexagonal Architecture) was introduced by Alistair Cockburn. The core idea is to isolate the application's business logic from external concerns through well-defined interfaces (ports) and their implementations (adapters).

## Core Concepts

### The Hexagon

The hexagon represents your application core - the business logic that doesn't depend on any external technology. Everything outside the hexagon is an external concern that communicates through ports.

```text
                    ┌─────────────────┐
                    │   HTTP API      │
                    │   (Adapter)     │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  Driving Port   │
                    │  IOrderService  │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        │         ┌──────────▼──────────┐         │
        │         │                     │         │
        │         │    APPLICATION      │         │
        │         │    CORE             │         │
        │         │                     │         │
        │         │  ┌───────────────┐  │         │
        │         │  │    DOMAIN     │  │         │
        │         │  │   ENTITIES    │  │         │
        │         │  └───────────────┘  │         │
        │         │                     │         │
        │         └──────────┬──────────┘         │
        │                    │                    │
        └────────────────────┼────────────────────┘
                             │
                    ┌────────▼────────┐
                    │  Driven Port    │
                    │ IOrderRepository│
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │   PostgreSQL    │
                    │   (Adapter)     │
                    └─────────────────┘
```

### Driving vs Driven

| Aspect | Driving (Primary) | Driven (Secondary) |
| --- | --- | --- |
| Direction | Outside → Inside | Inside → Outside |
| Who calls | External actors call application | Application calls external systems |
| Examples | HTTP Controllers, CLI, Tests | Database, Email, External APIs |
| Port implementation | Application implements the port | Adapter implements the port |

## Implementing Ports

### Driving Ports (Primary Ports)

These are interfaces that define what the application offers to the outside world.

```csharp
// Driving port - defines what the application does
public interface IOrderService
{
    Task<OrderDto> PlaceOrder(PlaceOrderRequest request);
    Task<OrderDto> GetOrder(Guid orderId);
    Task CancelOrder(Guid orderId);
}

// Application implements this interface
public class OrderService : IOrderService
{
    private readonly IOrderRepository _repository;
    private readonly IPaymentGateway _paymentGateway;

    public async Task<OrderDto> PlaceOrder(PlaceOrderRequest request)
    {
        // Business logic here
        var order = Order.Create(request.CustomerId, request.Items);

        // Uses driven ports
        await _repository.Save(order);
        await _paymentGateway.ProcessPayment(order.Total);

        return order.ToDto();
    }
}
```

### Driven Ports (Secondary Ports)

These are interfaces that define what the application needs from the outside world.

```csharp
// Driven port - defines what the application needs
public interface IOrderRepository
{
    Task<Order?> GetById(Guid id);
    Task Save(Order order);
    Task<IReadOnlyList<Order>> GetByCustomer(Guid customerId);
}

public interface IPaymentGateway
{
    Task<PaymentResult> ProcessPayment(decimal amount, PaymentDetails details);
    Task RefundPayment(Guid transactionId);
}

public interface IEmailNotifier
{
    Task SendOrderConfirmation(Order order);
}
```

## Implementing Adapters

### Driving Adapters (Primary Adapters)

These translate external requests into application calls.

```csharp
// HTTP Adapter (driving)
[ApiController]
[Route("api/orders")]
public class OrdersController : ControllerBase
{
    private readonly IOrderService _orderService;

    public OrdersController(IOrderService orderService)
    {
        _orderService = orderService;
    }

    [HttpPost]
    public async Task<IActionResult> PlaceOrder([FromBody] PlaceOrderRequest request)
    {
        var order = await _orderService.PlaceOrder(request);
        return CreatedAtAction(nameof(GetOrder), new { id = order.Id }, order);
    }
}

// CLI Adapter (driving)
public class OrderCli
{
    private readonly IOrderService _orderService;

    public async Task PlaceOrder(string[] args)
    {
        var request = ParseArgs(args);
        var order = await _orderService.PlaceOrder(request);
        Console.WriteLine($"Order {order.Id} placed successfully");
    }
}
```

### Driven Adapters (Secondary Adapters)

These implement the ports that the application needs.

```csharp
// PostgreSQL Adapter (driven)
public class PostgresOrderRepository : IOrderRepository
{
    private readonly OrderingDbContext _context;

    public async Task<Order?> GetById(Guid id)
    {
        return await _context.Orders
            .Include(o => o.Items)
            .FirstOrDefaultAsync(o => o.Id == id);
    }

    public async Task Save(Order order)
    {
        _context.Orders.Add(order);
        await _context.SaveChangesAsync();
    }
}

// Stripe Adapter (driven)
public class StripePaymentGateway : IPaymentGateway
{
    private readonly StripeClient _client;

    public async Task<PaymentResult> ProcessPayment(decimal amount, PaymentDetails details)
    {
        var paymentIntent = await _client.PaymentIntents.CreateAsync(
            new PaymentIntentCreateOptions
            {
                Amount = (long)(amount * 100),
                Currency = "usd",
                PaymentMethod = details.MethodId
            });

        return new PaymentResult(paymentIntent.Id, paymentIntent.Status == "succeeded");
    }
}
```

## Project Organization

### Recommended Structure

```text
src/
├── Module.Core/                    # The Hexagon
│   ├── Domain/                     # Domain entities, value objects
│   │   ├── Order.cs
│   │   ├── OrderItem.cs
│   │   └── OrderStatus.cs
│   ├── Application/                # Use cases, handlers
│   │   ├── Commands/
│   │   │   └── PlaceOrderHandler.cs
│   │   └── Queries/
│   │       └── GetOrderHandler.cs
│   └── Ports/                      # All port interfaces
│       ├── Driving/
│       │   └── IOrderService.cs
│       └── Driven/
│           ├── IOrderRepository.cs
│           └── IPaymentGateway.cs
│
├── Module.Infrastructure/          # Driven Adapters
│   ├── Persistence/
│   │   ├── OrderingDbContext.cs
│   │   └── PostgresOrderRepository.cs
│   ├── Payment/
│   │   └── StripePaymentGateway.cs
│   └── Notifications/
│       └── SendGridEmailNotifier.cs
│
└── Module.Api/                     # Driving Adapters
    └── Controllers/
        └── OrdersController.cs
```

## Dependency Rule

**The critical rule:** Dependencies always point inward. The core (domain + application) has no dependencies on infrastructure or adapters.

```text
API → Application → Domain ← Infrastructure
       (uses)       (implements)
```

- Core projects reference nothing external
- Infrastructure references Core (to implement ports)
- API references Core (to call services) and Infrastructure (for DI registration)

## Testing Benefits

Hexagonal architecture makes testing straightforward:

```csharp
// Unit test with fake adapters
public class OrderServiceTests
{
    [Fact]
    public async Task PlaceOrder_ShouldSaveOrder()
    {
        // Arrange - use in-memory fakes
        var repository = new InMemoryOrderRepository();
        var paymentGateway = new FakePaymentGateway(alwaysSucceed: true);
        var service = new OrderService(repository, paymentGateway);

        // Act
        var result = await service.PlaceOrder(new PlaceOrderRequest(...));

        // Assert
        var saved = await repository.GetById(result.Id);
        Assert.NotNull(saved);
    }
}
```

## Common Mistakes

1. **Leaking infrastructure types** - Domain should not reference EF Core's `DbSet<T>`
2. **Putting business logic in adapters** - Controllers should only translate and delegate
3. **Anemic ports** - Ports should reflect business operations, not CRUD
4. **Too many ports** - Group related operations in cohesive interfaces

## When to Use

**Good fit:**

- Applications with complex business logic
- Systems needing multiple adapters (different databases, APIs)
- Long-lived applications requiring testability
- Teams wanting clear separation of concerns

**Consider alternatives:**

- Simple CRUD applications (overhead may not be worth it)
- Prototypes or throwaway code
- Very small microservices

---

**Related:** `module-communication.md`, `data-patterns.md`
