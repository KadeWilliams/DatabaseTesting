using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using MyApplication.Core.Interfaces;

namespace MyApplication.Web.Pages.Customers;

public class EditModel : PageModel
{
    private readonly ICustomerRepository _customerRepository;

    public EditModel(ICustomerRepository customerRepository)
    {
        _customerRepository = customerRepository;
    }

    [BindProperty]
    public CustomerInput Customer { get; set; } = new();

    public async Task<IActionResult> OnGetAsync(int id)
    {
        var customer = await _customerRepository.GetByIdAsync(id);
        if (customer is null)
        {
            return RedirectToPage("Index");
        }

        Customer = new CustomerInput
        {
            CustomerId = customer.CustomerId,
            FirstName = customer.FirstName,
            LastName = customer.LastName,
            Email = customer.Email
        };
        return Page();
    }

    public async Task<IActionResult> OnPostAsync()
    {
        if (!ModelState.IsValid)
        {
            return Page();
        }

        try
        {
            await _customerRepository.UpdateAsync(new Core.Models.Customer
            {
                CustomerId = Customer.CustomerId,
                FirstName = Customer.FirstName,
                LastName = Customer.LastName,
                Email = Customer.Email
            });
        }
        catch (Microsoft.Data.SqlClient.SqlException ex) when (ex.Number == 2601 || ex.Number == 2627)
        {
            ModelState.AddModelError(string.Empty, "A customer with that email already exists.");
            return Page();
        }

        TempData["Message"] = "Customer updated.";
        return RedirectToPage("Index");
    }

    public class CustomerInput
    {
        public int CustomerId { get; set; }

        [Required, StringLength(100)]
        public string FirstName { get; set; } = string.Empty;

        [Required, StringLength(100)]
        public string LastName { get; set; } = string.Empty;

        [Required, EmailAddress, StringLength(256)]
        public string Email { get; set; } = string.Empty;
    }
}
