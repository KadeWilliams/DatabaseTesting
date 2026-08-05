using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Mvc.Rendering;
using MyApplication.Core.Interfaces;
using MyApplication.Core.Models;

namespace MyApplication.Web.Pages.Orders;

public class CreateModel : PageModel
{
    private const int InitialLineItemRows = 3;

    private readonly ICustomerRepository _customerRepository;
    private readonly IStatusRepository _statusRepository;
    private readonly IOrderRepository _orderRepository;

    public CreateModel(ICustomerRepository customerRepository, IStatusRepository statusRepository, IOrderRepository orderRepository)
    {
        _customerRepository = customerRepository;
        _statusRepository = statusRepository;
        _orderRepository = orderRepository;
    }

    [BindProperty]
    public OrderInput Order { get; set; } = new();

    public List<SelectListItem> CustomerOptions { get; set; } = new();
    public List<SelectListItem> StatusOptions { get; set; } = new();

    public async Task OnGetAsync(int? customerId)
    {
        await LoadOptionsAsync();
        Order.CustomerId = customerId ?? 0;

        var pendingStatus = StatusOptions.FirstOrDefault(s => s.Text == "Pending");
        if (pendingStatus is not null)
        {
            Order.StatusId = int.Parse(pendingStatus.Value);
        }

        for (var i = 0; i < InitialLineItemRows; i++)
        {
            Order.LineItems.Add(new LineItemInput());
        }
    }

    public async Task<IActionResult> OnPostAsync()
    {
        await LoadOptionsAsync();

        var lineItems = Order.LineItems
            .Where(li => !string.IsNullOrWhiteSpace(li.ProductName) && li.Quantity > 0)
            .ToList();

        if (!ModelState.IsValid)
        {
            return Page();
        }

        var orderId = await _orderRepository.InsertAsync(
            Order.CustomerId,
            Order.StatusId,
            Order.Notes,
            lineItems.Select(li => new OrderLineItem
            {
                ProductName = li.ProductName!,
                Quantity = li.Quantity,
                UnitPrice = li.UnitPrice
            }));

        TempData["Message"] = $"Order #{orderId} created.";
        return RedirectToPage("Details", new { id = orderId });
    }

    private async Task LoadOptionsAsync()
    {
        var customers = await _customerRepository.GetAllAsync();
        CustomerOptions = customers
            .Select(c => new SelectListItem($"{c.FirstName} {c.LastName}", c.CustomerId.ToString()))
            .ToList();

        var statuses = await _statusRepository.GetAllAsync();
        StatusOptions = statuses
            .Select(s => new SelectListItem(s.Name, s.StatusId.ToString()))
            .ToList();
    }

    public class OrderInput
    {
        [Range(1, int.MaxValue, ErrorMessage = "Please select a customer.")]
        public int CustomerId { get; set; }

        public int StatusId { get; set; } = 1;

        [StringLength(400)]
        public string? Notes { get; set; }

        public List<LineItemInput> LineItems { get; set; } = new();
    }

    public class LineItemInput
    {
        [StringLength(200)]
        public string? ProductName { get; set; }

        public int Quantity { get; set; }

        public decimal UnitPrice { get; set; }
    }
}
