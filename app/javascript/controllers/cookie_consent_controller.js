import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "cookie_consent"

export default class extends Controller {
  connect() {
    const choice = this.storedChoice()

    if (choice === "accepted") {
      this.grantAnalyticsConsent()
    } else if (choice === null) {
      this.element.classList.remove("hidden")
    }
  }

  accept() {
    this.storeChoice("accepted")
    this.grantAnalyticsConsent()
    this.element.classList.add("hidden")
  }

  decline() {
    this.storeChoice("declined")
    this.element.classList.add("hidden")
  }

  storedChoice() {
    try {
      return window.localStorage.getItem(STORAGE_KEY)
    } catch {
      return null
    }
  }

  storeChoice(value) {
    try {
      window.localStorage.setItem(STORAGE_KEY, value)
    } catch {
      // Private browsing or blocked storage — the banner will just show
      // again next visit, which is an acceptable degradation.
    }
  }

  grantAnalyticsConsent() {
    if (typeof window.gtag === "function") {
      window.gtag("consent", "update", { analytics_storage: "granted" })
    }
  }
}
