import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "panel", "button" ]

  toggle() {
    const isOpen = !this.panelTarget.hidden
    this.panelTarget.hidden = isOpen
    this.buttonTarget.setAttribute("aria-expanded", (!isOpen).toString())
  }

  close() {
    this.panelTarget.hidden = true
    this.buttonTarget.setAttribute("aria-expanded", "false")
  }
}
