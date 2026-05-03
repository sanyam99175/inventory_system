import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle() {
    const menu = document.getElementById("mobile-menu")
    const menuIcon = document.getElementById("menu-icon")
    const closeIcon = document.getElementById("close-icon")

    menu.classList.toggle("hidden")
    menuIcon.classList.toggle("hidden")
    closeIcon.classList.toggle("hidden")
  }

  disconnect() {
    const menu = document.getElementById("mobile-menu")
    const menuIcon = document.getElementById("menu-icon")
    const closeIcon = document.getElementById("close-icon")

    if (menu) menu.classList.add("hidden")
    if (menuIcon) menuIcon.classList.remove("hidden")
    if (closeIcon) closeIcon.classList.add("hidden")
  }
}
