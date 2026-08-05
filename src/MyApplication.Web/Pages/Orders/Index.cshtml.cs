using Microsoft.AspNetCore.Mvc.RazorPages;
using MyApplication.Core.Interfaces;
using MyApplication.Core.Models;

namespace MyApplication.Web.Pages.Orders;

public class IndexModel : PageModel
{
    private readonly IOrderRepository _orderRepository;

    public IndexModel(IOrderRepository orderRepository)
    {
        _orderRepository = orderRepository;
    }

    public IEnumerable<Order> Orders { get; set; } = Enumerable.Empty<Order>();

    public async Task OnGetAsync()
    {
        Orders = await _orderRepository.GetAllAsync();
    }
}
