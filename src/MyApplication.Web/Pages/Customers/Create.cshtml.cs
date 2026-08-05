using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using MyApplication.Core.Interfaces;

namespace MyApplication.Web.Pages.Customers;

public class CreateModel : PageModel
{
    private readonly ICustomerRepository _customerRepository;

    public CreateModel(ICustomerRepository customerRepository)
    {
        _customerRepository = customerRepository;
    }

    [BindProperty]
    public CustomerInput Customer { get; set; } = new();

    public async Task<IActionResult> OnPostAsync()
    {
        if (!ModelState.IsValid)
        {
            return Page();
        }

        var customer = new Core.Models.Customer
        {
            FirstName = Customer.FirstName,
            LastName = Customer.LastName,
            Email = Customer.Email
        };

        try
        {
            await _customerRepository.InsertAsync(customer);
        }
        catch (Microsoft.Data.SqlClient.SqlException ex) when (ex.Number == 2601 || ex.Number == 2627)
        {
            ModelState.AddModelError(string.Empty, "A customer with that email already exists.");
            return Page();
        }

        TempData["Message"] = $"Customer {customer.FirstName} {customer.LastName} created.";
        return RedirectToPage("Index");
    }

    public class CustomerInput
    {
        [Required, StringLength(100)]
        public string FirstName { get; set; } = string.Empty;

        [Required, StringLength(100)]
        public string LastName { get; set; } = string.Empty;

        [Required, EmailAddress, StringLength(256)]
        public string Email { get; set; } = string.Empty;
    }
}
