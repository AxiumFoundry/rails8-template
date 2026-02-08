import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    autoClose: { type: Boolean, default: true },
    delay: { type: Number, default: 5000 }
  }

  connect() {
    this.element.classList.add('animate-slide-in-right')

    if (this.autoCloseValue) {
      this.autoCloseTimeout = setTimeout(() => {
        this.close()
      }, this.delayValue)
    }

    const closeButton = this.element.querySelector('[data-action="click->flash#close"]')
    if (!closeButton && this.element.querySelector('button')) {
      const button = this.element.querySelector('button')
      button.setAttribute('data-action', 'click->flash#close')
    }
  }

  disconnect() {
    if (this.autoCloseTimeout) {
      clearTimeout(this.autoCloseTimeout)
    }
  }

  close(event) {
    if (event) {
      event.preventDefault()
    }

    if (this.autoCloseTimeout) {
      clearTimeout(this.autoCloseTimeout)
    }

    this.element.classList.add('animate-fade-out')

    setTimeout(() => {
      this.element.remove()
    }, 300)
  }

  mouseenter() {
    if (this.autoCloseTimeout) {
      clearTimeout(this.autoCloseTimeout)
      this.autoCloseTimeout = null
    }
  }

  mouseleave() {
    if (this.autoCloseValue && !this.autoCloseTimeout) {
      this.autoCloseTimeout = setTimeout(() => {
        this.close()
      }, 2000)
    }
  }
}
