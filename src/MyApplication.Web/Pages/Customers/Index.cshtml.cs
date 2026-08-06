using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using MyApplication.Core.Interfaces;
using MyApplication.Core.Models;

namespace MyApplication.Web.Pages.Customers;

public class IndexModel : PageModel
{
    private readonly ICustomerRepository _customerRepository;

    public IndexModel(ICustomerRepository customerRepository)
    {
        _customerRepository = customerRepository;
    }

    [BindProperty(SupportsGet = true)]
    public string? Search { get; set; }

    public IEnumerable<Customer> Customers { get; set; } = Enumerable.Empty<Customer>();

    public async Task OnGetAsync()
    {
        Customers = await _customerRepository.GetAllAsync(Search);
    }
}
