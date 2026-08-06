using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using MyApplication.Core.Interfaces;
using MyApplication.Core.Models;

namespace MyApplication.Web.Pages.Customers;

public class DeleteModel : PageModel
{
    private readonly ICustomerRepository _customerRepository;

    public DeleteModel(ICustomerRepository customerRepository)
    {
        _customerRepository = customerRepository;
    }

    public Customer? Customer { get; set; }

    public async Task<IActionResult> OnGetAsync(int id)
    {
        Customer = await _customerRepository.GetByIdAsync(id);
        return Page();
    }

    public async Task<IActionResult> OnPostAsync(int id)
    {
        try
        {
            await _customerRepository.DeleteAsync(id);
            TempData["Message"] = "Customer deleted.";
        }
        catch (Microsoft.Data.SqlClient.SqlException ex) when (ex.Number == 547)
        {
            TempData["Error"] = "That customer has existing orders and can't be deleted.";
        }

        return RedirectToPage("Index");
    }
}
