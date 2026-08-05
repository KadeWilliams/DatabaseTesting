namespace MyApplication.Core.Models;

public class Order
{
    public int OrderId { get; set; }
    public int CustomerId { get; set; }
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public int StatusId { get; set; }
    public string StatusName { get; set; } = string.Empty;
    public DateTime OrderDate { get; set; }
    public string? Notes { get; set; }
    public decimal OrderTotal { get; set; }
    public List<OrderLineItem> LineItems { get; set; } = new();
}
