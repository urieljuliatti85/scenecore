module Admin::NavHelper
  def admin_nav_link(label, path, current:, section: nil)
    classes = [ "group flex items-center gap-3 rounded-r-xl border-l-2 px-3 py-2.5 text-sm font-medium transition" ]
    classes << if current
      "border-fuchsia-400 bg-fuchsia-500/15 text-fuchsia-100"
    else
      "border-transparent text-slate-400 hover:border-cyan-400/60 hover:bg-white/5 hover:text-white"
    end

    link_to path, class: classes.join(" "), aria: { current: ("page" if current) } do
      safe_join([
        render("admin/nav_icon", section: section || :dashboard, current: current),
        tag.span(label, class: "truncate")
      ])
    end
  end
end
