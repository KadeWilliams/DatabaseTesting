using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Mvc.Rendering;
using MyApplication.Core.Interfaces;
using MyApplication.Core.Models;

namespace MyApplication.Web.Pages.Orders;

public class DetailsModel : PageModel
{
    private readonly IOrderRepository _orderRepository;
    private readonly IStatusRepository _statusRepository;

    public DetailsModel(IOrderRepository orderRepository, IStatusRepository statusRepository)
    {
        _orderRepository = orderRepository;
        _statusRepository = statusRepository;
    }

    public Order? Order { get; set; }
    public List<SelectListItem> StatusOptions { get; set; } = new();

    public async Task OnGetAsync(int id)
    {
        Order = await _orderRepository.GetByIdAsync(id);
        await LoadStatusOptionsAsync();
    }

    public async Task<IActionResult> OnPostAsync(int id, int statusId)
    {
        await _orderRepository.UpdateStatusAsync(id, statusId);
        TempData["Message"] = "Order status updated.";
        return RedirectToPage("Details", new { id });
    }

    private async Task LoadStatusOptionsAsync()
    {
        var statuses = await _statusRepository.GetAllAsync();
        StatusOptions = statuses
            .Select(s => new SelectListItem(s.Name, s.StatusId.ToString(), Order is not null && s.StatusId == Order.StatusId))
            .ToList();
    }
}
