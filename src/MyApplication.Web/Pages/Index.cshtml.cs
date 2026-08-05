using Microsoft.AspNetCore.Mvc.RazorPages;
using MyApplication.Core.Interfaces;

namespace MyApplication.Web.Pages;

public class IndexModel : PageModel
{
    private readonly ICustomerRepository _customerRepository;
    private readonly IOrderRepository _orderRepository;

    public IndexModel(ICustomerRepository customerRepository, IOrderRepository orderRepository)
    {
        _customerRepository = customerRepository;
        _orderRepository = orderRepository;
    }

    public int CustomerCount { get; set; }
    public int OrderCount { get; set; }

    public async Task OnGetAsync()
    {
        var customers = await _customerRepository.GetAllAsync();
        var orders = await _orderRepository.GetAllAsync();
        CustomerCount = customers.Count();
        OrderCount = orders.Count();
    }
}
