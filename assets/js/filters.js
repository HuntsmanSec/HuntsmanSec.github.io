document.querySelectorAll("[data-filter-root]").forEach((root) => {
  const buttons = [...root.querySelectorAll("[data-filter]")];
  const cards = [...root.querySelectorAll("[data-tags]")];
  const emptyState = root.querySelector("[data-empty-state]");

  buttons.forEach((button) => {
    button.addEventListener("click", () => {
      const filter = button.dataset.filter;
      let visibleCount = 0;

      buttons.forEach((item) => item.classList.remove("active"));
      button.classList.add("active");

      cards.forEach((card) => {
        const tags = card.dataset.tags.split(" ").filter(Boolean);
        const isVisible = filter === "all" || tags.includes(filter);
        card.hidden = !isVisible;
        if (isVisible) visibleCount += 1;
      });

      if (emptyState) emptyState.hidden = visibleCount !== 0;
    });
  });
});

document.querySelectorAll("[data-modal-open]").forEach((button) => {
  button.addEventListener("click", () => {
    const modal = document.getElementById(button.dataset.modalOpen);
    if (!modal) return;

    modal.classList.add("open");
    modal.setAttribute("aria-hidden", "false");
    document.body.classList.add("modal-active");

    const closeButton = modal.querySelector("[data-modal-close]");
    if (closeButton) closeButton.focus();
  });
});

document.querySelectorAll("[data-modal-close]").forEach((button) => {
  button.addEventListener("click", () => {
    const modal = button.closest(".modal");
    if (!modal) return;

    modal.classList.remove("open");
    modal.setAttribute("aria-hidden", "true");
    document.body.classList.remove("modal-active");
  });
});

document.addEventListener("keydown", (event) => {
  if (event.key !== "Escape") return;

  document.querySelectorAll(".modal.open").forEach((modal) => {
    modal.classList.remove("open");
    modal.setAttribute("aria-hidden", "true");
  });
  document.body.classList.remove("modal-active");
});
