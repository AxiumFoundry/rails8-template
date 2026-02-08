import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button", "arrow"]

  connect() {
    this.isOpen = false
  }

  toggle(event) {
    event.stopPropagation()

    if (this.isOpen) {
      this.hide()
    } else {
      this.show()
    }
  }

  show() {
    this.isOpen = true
    this.menuTarget.classList.remove("hidden")

    if (this.hasArrowTarget) {
      this.arrowTarget.classList.add("rotate-180")
    }

    this.dispatch("open")
  }

  hide() {
    if (event && this.menuTarget.contains(event.target)) {
      return
    }

    this.isOpen = false
    this.menuTarget.classList.add("hidden")

    if (this.hasArrowTarget) {
      this.arrowTarget.classList.remove("rotate-180")
    }
  }

  hideOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hide()
    }
  }

  closeOthers(event) {
    if (event.target !== this.element) {
      this.hide()
    }
  }
}
