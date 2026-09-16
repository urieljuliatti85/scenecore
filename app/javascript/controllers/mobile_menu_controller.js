import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "panel", "button" ]

  toggle() {
    const isOpen = this.panelTarget.classList.contains("hidden")
    this.panelTarget.classList.toggle("hidden", !isOpen)
    this.buttonTarget.setAttribute("aria-expanded", isOpen.toString())
  }

  close() {
    this.panelTarget.classList.add("hidden")
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }
}
