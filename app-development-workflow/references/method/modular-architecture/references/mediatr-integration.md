# MediatR Integration for Modular Monoliths

## Overview

MediatR provides the messaging infrastructure for CQRS within modules and integration events across modules. This guide covers configuration and patterns for modular monolith architecture.

## Installation

```bash
dotnet add package MediatR
dotnet add package MediatR.Extensions.Microsoft.DependencyInjection
```

## Module Registration Pattern

### Per-Module Registration

Each module registers its own handlers:

```csharp
// Ordering.Core/OrderingModule.cs
public static class OrderingModule
{
    public static IServiceCollection AddOrderingModule(
        this IServiceCollection services,
        string connectionString)
    {
        // Register MediatR handlers from this assembly
        services.AddMediatR(cfg =>
            cfg.RegisterServicesFromAssembly(typeof(OrderingModule).Assembly));

        // Register module services
        services.AddScoped<IOrderingModuleApi, OrderingModuleApi>();

        // Register DbContext
        services.AddDbContext<OrderingDbContext>(options =>
            options.UseNpgsql(connectionString));

        // Register repositories
        services.AddScoped<IOrderRepository, OrderRepository>();

        return services;
    }
}

// Inventory.Core/InventoryModule.cs
public static class InventoryModule
{
    public static IServiceCollection AddInventoryModule(
        this IServiceCollection services,
        string connectionString)
    {
        services.AddMediatR(cfg =>
            cfg.RegisterServicesFromAssembly(typeof(InventoryModule).Assembly));

        services.AddScoped<IInventoryModuleApi, InventoryModuleApi>();
        services.AddDbContext<InventoryDbContext>(options =>
            options.UseNpgsql(connectionString));

        return services;
    }
}
```

### Host Registration

```csharp
// Program.cs
var builder = WebApplication.CreateBuilder(args);

var connectionString = builder.Configuration.GetConnectionString("Default");

builder.Services
    .AddOrderingModule(connectionString)
    .AddInventoryModule(connectionString)
    .AddShippingModule(connectionString);

var app = builder.Build();
```

## Command and Query Patterns

### Commands (State Changes)

```csharp
// Command definition
public record PlaceOrderCommand(
    Guid CustomerId,
    List<OrderItemDto> Items
) : IRequest<OrderDto>;

// Command handler
public class PlaceOrderHandler : IRequestHandler<PlaceOrderCommand, OrderDto>
{
    private readonly IOrderRepository _repository;
    private readonly IMediator _mediator;

    public PlaceOrderHandler(IOrderRepository repository, IMediator mediator)
    {
        _repository = repository;
        _mediator = mediator;
    }

    public async Task<OrderDto> Handle(PlaceOrderCommand request, CancellationToken ct)
    {
        var order = Order.Create(request.CustomerId, request.Items);

        await _repository.Save(order);

        // Publish domain events after state change
        foreach (var domainEvent in order.DomainEvents)
        {
            await _mediator.Publish(domainEvent, ct);
        }

        return order.ToDto();
    }
}
```

### Queries (Read Operations)

```csharp
// Query definition
public record GetOrderQuery(Guid OrderId) : IRequest<OrderDto?>;

// Query handler
public class GetOrderHandler : IRequestHandler<GetOrderQuery, OrderDto?>
{
    private readonly IOrderRepository _repository;

    public GetOrderHandler(IOrderRepository repository)
    {
        _repository = repository;
    }

    public async Task<OrderDto?> Handle(GetOrderQuery request, CancellationToken ct)
    {
        var order = await _repository.GetById(request.OrderId);
        return order?.ToDto();
    }
}
```

## Domain Events vs Integration Events

### Domain Events (Within Module)

Internal to the module, part of the aggregate lifecycle:

```csharp
// Domain event - internal to Ordering module
public record OrderPlacedDomainEvent(Order Order) : INotification;

// Handler within same module
public class UpdateOrderStatisticsHandler : INotificationHandler<OrderPlacedDomainEvent>
{
    public async Task Handle(OrderPlacedDomainEvent notification, CancellationToken ct)
    {
        // Update internal module statistics
        await _statisticsService.IncrementOrderCount();
    }
}
```

### Integration Events (Cross-Module)

Published for other modules to consume:

```csharp
// Integration event - in DataTransfer project
public record OrderPlacedIntegrationEvent(
    Guid OrderId,
    Guid CustomerId,
    List<OrderedItemDto> Items,
    decimal Total
) : INotification;

// Handler in different module (Inventory)
public class ReserveInventoryHandler : INotificationHandler<OrderPlacedIntegrationEvent>
{
    public async Task Handle(OrderPlacedIntegrationEvent notification, CancellationToken ct)
    {
        foreach (var item in notification.Items)
        {
            await _inventoryService.Reserve(item.ProductId, item.Quantity);
        }
    }
}
```

## Pipeline Behaviors

### Logging Behavior

```csharp
public class LoggingBehavior<TRequest, TResponse>
    : IPipelineBehavior<TRequest, TResponse>
    where TRequest : notnull
{
    private readonly ILogger<LoggingBehavior<TRequest, TResponse>> _logger;

    public async Task<TResponse> Handle(
        TRequest request,
        RequestHandlerDelegate<TResponse> next,
        CancellationToken ct)
    {
        var requestName = typeof(TRequest).Name;

        _logger.LogInformation("Handling {RequestName}: {@Request}", requestName, request);

        var response = await next();

        _logger.LogInformation("Handled {RequestName}", requestName);

        return response;
    }
}
```

### Validation Behavior

```csharp
public class ValidationBehavior<TRequest, TResponse>
    : IPipelineBehavior<TRequest, TResponse>
    where TRequest : notnull
{
    private readonly IEnumerable<IValidator<TRequest>> _validators;

    public async Task<TResponse> Handle(
        TRequest request,
        RequestHandlerDelegate<TResponse> next,
        CancellationToken ct)
    {
        if (!_validators.Any())
            return await next();

        var context = new ValidationContext<TRequest>(request);
        var failures = _validators
            .Select(v => v.Validate(context))
            .SelectMany(r => r.Errors)
            .Where(f => f != null)
            .ToList();

        if (failures.Any())
            throw new ValidationException(failures);

        return await next();
    }
}
```

### Registration

```csharp
services.AddMediatR(cfg =>
{
    cfg.RegisterServicesFromAssembly(typeof(OrderingModule).Assembly);
    cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(LoggingBehavior<,>));
    cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));
});
```

## Best Practices

1. **Commands return DTOs, not entities** - Never expose domain objects
2. **One handler per command/query** - Keep handlers focused
3. **Use integration events for cross-module** - Don't reference other modules directly
4. **Pipeline behaviors for cross-cutting** - Logging, validation, transactions
5. **Keep notifications async** - Don't block on integration event handlers

---

**Related:** `module-communication.md`, `data-patterns.md`
