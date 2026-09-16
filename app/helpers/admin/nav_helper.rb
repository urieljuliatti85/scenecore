module Admin::NavHelper
  def admin_nav_link(label, path, current:)
    classes = [ "rounded-lg px-3 py-2 text-sm font-medium transition" ]
    classes << (current ? "bg-white text-black" : "text-neutral-300 hover:text-white hover:bg-neutral-900")

    link_to label, path, class: classes.join(" ")
  end
end
