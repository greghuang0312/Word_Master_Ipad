# Module Communication Patterns

## Overview

In a modular monolith, modules must communicate without creating tight coupling. This guide covers synchronous and asynchronous communication patterns between modules.

## Communication Principles

### The Golden Rule

**Modules cannot reference each other's Core/Domain projects.** All cross-module communication happens through:

1. **DataTransfer projects** (for synchronous queries)
2. **Integration events** (for asynchronous reactions)

### When to Use Each

| Pattern | Use Case | Consistency | Coupling |
| --- | --- | --- | --- |
| Synchronous (DataTransfer) | Queries, read operations | Strong | Moderate |
| Asynchronous (Events) | Commands, state changes | Eventual | Low |

## Synchronous Communication

### DataTransfer Pattern

Each module exposes a DataTransfer project containing:

- DTOs (Data Transfer Objects)
- A module API interface

```csharp
// Ordering.DataTransfer/OrderDto.cs
public record OrderDto(
    Guid Id,
    Guid CustomerId,
    DateTime PlacedAt,
    decimal Total,
    string Status,
    IReadOnlyList<OrderItemDto> Items
);

public record OrderItemDto(
    Guid ProductId,
    int Quantity,
    decimal UnitPrice
);

// Ordering.DataTransfer/IOrderingModuleApi.cs
public interface IOrderingModuleApi
{
    Task<OrderDto?> GetOrder(Guid orderId);
    Task<OrderSummaryDto?> GetOrderSummary(Guid orderId);
    Task<IReadOnlyList<OrderDto>> GetCustomerOrders(Guid customerId);
}
```

### Implementing the Module API

```csharp
// Ordering.Core/OrderingModuleApi.cs
internal class OrderingModuleApi : IOrderingModuleApi
{
    private readonly IOrderRepository _repository;

    public OrderingModuleApi(IOrderRepository repository)
    {
        _repository = repository;
    }

    public async Task<OrderDto?> GetOrder(Guid orderId)
    {
        var order = await _repository.GetById(orderId);
        return order?.ToDto();  // Domain entity → DTO mapping
    }

    public async Task<OrderSummaryDto?> GetOrderSummary(Guid orderId)
    {
        var order = await _repository.GetById(orderId);
        if (order == null) return null;

        return new OrderSummaryDto(
            order.Id,
            order.Total,
            order.Status.ToString(),
            order.Items.Count
        );
    }
}
```

### Consuming Another Module

```csharp
// Shipping.Core/Handlers/CreateShipmentHandler.cs
public class CreateShipmentHandler
{
    private readonly IOrderingModuleApi _orderingApi;  // From DataTransfer
    private readonly IShipmentRepository _shipmentRepo;

    public CreateShipmentHandler(
        IOrderingModuleApi orderingApi,
        IShipmentRepository shipmentRepo)
    {
        _orderingApi = orderingApi;
        _shipmentRepo = shipmentRepo;
    }

    public async Task<ShipmentDto> Handle(CreateShipmentCommand command)
    {
        // Query order from Ordering module
        var order = await _orderingApi.GetOrder(command.OrderId);
        if (order == null)
            throw new OrderNotFoundException(command.OrderId);

        // Create shipment using order data
        var shipment = Shipment.Create(
            order.Id,
            order.Items.Select(i => new ShipmentItem(i.ProductId, i.Quantity))
        );

        await _shipmentRepo.Save(shipment);
        return shipment.ToDto();
    }
}
```

## Asynchronous Communication

### Integration Events with MediatR

For state changes that other modules should react to:

```csharp
// Shared.Kernel/IntegrationEvent.cs
public abstract record IntegrationEvent(Guid EventId, DateTime OccurredAt)
{
    protected IntegrationEvent() : this(Guid.NewGuid(), DateTime.UtcNow) { }
}

// Ordering.DataTransfer/Events/OrderPlacedIntegrationEvent.cs
public record OrderPlacedIntegrationEvent(
    Guid OrderId,
    Guid CustomerId,
    IReadOnlyList<OrderedItemDto> Items,
    decimal Total
) : IntegrationEvent;

public record OrderedItemDto(Guid ProductId, int Quantity);
```

### Publishing Integration Events

```csharp
// Ordering.Core/Handlers/PlaceOrderHandler.cs
public class PlaceOrderHandler
{
    private readonly IOrderRepository _repository;
    private readonly IMediator _mediator;

    public async Task<OrderDto> Handle(PlaceOrderCommand command)
    {
        var order = Order.Create(command.CustomerId, command.Items);

        await _repository.Save(order);

        // Publish integration event for other modules
        await _mediator.Publish(new OrderPlacedIntegrationEvent(
            order.Id,
            order.CustomerId,
            order.Items.Select(i => new OrderedItemDto(i.ProductId, i.Quantity)).ToList(),
            order.Total
        ));

        return order.ToDto();
    }
}
```

### Handling Integration Events

```csharp
// Inventory.Core/Handlers/OrderPlacedHandler.cs
public class OrderPlacedHandler : INotificationHandler<OrderPlacedIntegrationEvent>
{
    private readonly IInventoryService _inventoryService;
    private readonly ILogger<OrderPlacedHandler> _logger;

    public async Task Handle(
        OrderPlacedIntegrationEvent notification,
        CancellationToken cancellationToken)
    {
        _logger.LogInformation(
            "Reserving inventory for order {OrderId}",
            notification.OrderId);

        foreach (var item in notification.Items)
        {
            await _inventoryService.ReserveStock(
                item.ProductId,
                item.Quantity,
                notification.OrderId);
        }
    }
}

// Notification.Core/Handlers/OrderPlacedEmailHandler.cs
public class OrderPlacedEmailHandler : INotificationHandler<OrderPlacedIntegrationEvent>
{
    private readonly IEmailSender _emailSender;
    private readonly ICustomerModuleApi _customerApi;

    public async Task Handle(
        OrderPlacedIntegrationEvent notification,
        CancellationToken cancellationToken)
    {
        var customer = await _customerApi.GetCustomer(notification.CustomerId);

        await _emailSender.SendOrderConfirmation(
            customer.Email,
            notification.OrderId,
            notification.Total);
    }
}
```

## Event Choreography vs Orchestration

### Choreography (Preferred for Modules)

Each module reacts independently to events:

```text
OrderPlaced ──┬──► Inventory reserves stock
              ├──► Notification sends email
              └──► Analytics records sale
```

**Pros:** Low coupling, modules are independent
**Cons:** Hard to track overall flow, debugging across modules

### Orchestration (For Complex Workflows)

A coordinator drives the flow:

```text
Saga/Orchestrator ──► Reserve Inventory
                  ──► Process Payment
                  ──► Create Shipment
                  ──► Send Notification
```

**Pros:** Clear flow, easier debugging
**Cons:** Central point of failure, tighter coupling

## Error Handling

### Idempotent Handlers

Events may be delivered multiple times. Handlers must be idempotent:

```csharp
public class OrderPlacedHandler : INotificationHandler<OrderPlacedIntegrationEvent>
{
    public async Task Handle(OrderPlacedIntegrationEvent notification, CancellationToken ct)
    {
        // Check if already processed
        var existing = await _repository.GetReservation(notification.OrderId);
        if (existing != null)
        {
            _logger.LogInformation("Already processed order {OrderId}", notification.OrderId);
            return;
        }

        // Process the event
        await _inventoryService.ReserveStock(...);
    }
}
```

### Compensation Events

When things go wrong, publish compensation events:

```csharp
// If payment fails after inventory reserved
await _mediator.Publish(new OrderCancelledIntegrationEvent(orderId, "Payment failed"));

// Inventory module handles this
public class OrderCancelledHandler : INotificationHandler<OrderCancelledIntegrationEvent>
{
    public async Task Handle(OrderCancelledIntegrationEvent notification, CancellationToken ct)
    {
        await _inventoryService.ReleaseReservation(notification.OrderId);
    }
}
```

## Best Practices

1. **Keep DTOs simple** - Only data, no behavior
2. **Version integration events** - Include version in event type if schema changes
3. **Log event handling** - Track what events were processed
4. **Use correlation IDs** - Pass through for distributed tracing
5. **Handle failures gracefully** - Events should not crash the application

---

**Related:** `ports-adapters-guide.md`, `mediatr-integration.md`
