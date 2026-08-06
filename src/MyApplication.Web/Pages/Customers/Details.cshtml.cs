using Microsoft.AspNetCore.Mvc.RazorPages;
using MyApplication.Core.Interfaces;
using MyApplication.Core.Models;

namespace MyApplication.Web.Pages.Customers;

public class DetailsModel : PageModel
{
    private readonly ICustomerRepository _customerRepository;
    private readonly IOrderRepository _orderRepository;

    public DetailsModel(ICustomerRepository customerRepository, IOrderRepository orderRepository)
    {
        _customerRepository = customerRepository;
        _orderRepository = orderRepository;
    }

    public Customer? Customer { get; set; }
    public IEnumerable<Order> Orders { get; set; } = Enumerable.Empty<Order>();

    public async Task OnGetAsync(int id)
    {
        Customer = await _customerRepository.GetByIdAsync(id);
        if (Customer is not null)
        {
            Orders = await _orderRepository.GetByCustomerIdAsync(id);
        }
    }
}
