import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "overlay"]

  open() {
    this.panelTarget.classList.remove("translate-x-full")
    this.overlayTarget.classList.remove("hidden")

    const frame = document.getElementById("profile_drawer")

    // 🔥 FORCE LOAD (this is what was missing)
    frame.innerHTML = ""
    frame.setAttribute("src", "/users/edit")
  }

  close() {
    this.panelTarget.classList.add("translate-x-full")
    this.overlayTarget.classList.add("hidden")
  }
}