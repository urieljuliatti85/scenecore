module Admin::NavHelper
  def admin_nav_link(label, path, current:, section: nil)
    classes = [ "group flex items-center gap-2 rounded-md border-l-2 px-2.5 py-2 text-xs font-medium transition" ]
    classes << if current
      "border-yellow-400 bg-[#393939] text-white"
    else
      "border-transparent text-neutral-500 hover:border-yellow-400/50 hover:bg-[#292929] hover:text-neutral-100"
    end

    link_to path, class: classes.join(" "), aria: { current: ("page" if current) } do
      safe_join([
        render("admin/nav_icon", section: section || :dashboard, current: current),
        tag.span(label, class: "truncate")
      ])
    end
  end
end
