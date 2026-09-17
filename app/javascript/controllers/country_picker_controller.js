import { Controller } from "@hotwired/stimulus"

// Filters a long list of country checkboxes and keeps a count of what is
// selected. The list is rendered in full by the server, so the form still
// works without this controller — filtering is only there to make 249
// checkboxes usable.
export default class extends Controller {
  static targets = ["query", "option", "count"]

  connect() {
    this.updateCount()
  }

  filter() {
    const term = this.queryTarget.value.trim().toLowerCase()

    this.optionTargets.forEach((option) => {
      const name = option.dataset.countryName.toLowerCase()
      const code = option.dataset.countryCode.toLowerCase()
      const checked = option.querySelector("input[type=checkbox]").checked

      // A selected country stays visible whatever the filter, so nothing a
      // band has already picked can scroll out of sight unnoticed.
      option.hidden = term !== "" && !checked && !name.includes(term) && !code.startsWith(term)
    })
  }

  updateCount() {
    if (!this.hasCountTarget) return

    const total = this.optionTargets.filter(
      (option) => option.querySelector("input[type=checkbox]").checked
    ).length

    this.countTarget.textContent = total === 1 ? "1 country selected" : `${total} countries selected`
  }
}
