module Admin::NavHelper
  def admin_nav_link(label, path, current:, section: nil)
    classes = [ "group flex items-center gap-2.5 rounded-lg px-3 py-2 text-sm font-medium transition" ]
    classes << if current
      admin_section_accent(section, :active)
    else
      "text-neutral-300 hover:text-white hover:bg-neutral-900"
    end

    link_to path, class: classes.join(" ") do
      safe_join([ admin_nav_dot(section, current: current), label ])
    end
  end

  private

  # The dot carries the section's colour when the item is idle. On the active
  # item the accent has already moved to the background, so the dot switches
  # to a neutral tone that stays legible against it.
  def admin_nav_dot(section, current:)
    tone = current ? "bg-black/40" : admin_section_accent(section, :dot)

    tag.span("", class: "h-1.5 w-1.5 rounded-full shrink-0 #{tone}", aria: { hidden: true })
  end
end
