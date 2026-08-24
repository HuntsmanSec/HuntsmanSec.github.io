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

document.querySelectorAll("[data-dropdown]").forEach((dropdown) => {
  const trigger = dropdown.querySelector("[data-dropdown-trigger]");
  if (!trigger) return;

  const close = () => {
    dropdown.classList.remove("open");
    trigger.setAttribute("aria-expanded", "false");
  };

  trigger.addEventListener("click", () => {
    const isOpen = dropdown.classList.toggle("open");
    trigger.setAttribute("aria-expanded", String(isOpen));
  });

  document.addEventListener("click", (event) => {
    if (!dropdown.contains(event.target)) close();
  });

  dropdown.addEventListener("keydown", (event) => {
    if (event.key !== "Escape") return;
    close();
    trigger.focus();
  });
});

const scrambleTarget = document.querySelector("[data-scramble]");

if (scrambleTarget) {
  const finalText = scrambleTarget.dataset.scramble;
  const glyphs = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_#$%";

  const startScramble = () => {
    let frame = 0;
    const maxFrames = finalText.length * 5;
    scrambleTarget.classList.remove("glitch-complete");

    const scramble = () => {
      const output = finalText
        .split("")
        .map((char, index) => {
          if (frame / 5 > index) return char;
          return glyphs[Math.floor(Math.random() * glyphs.length)];
        })
        .join("");

      scrambleTarget.textContent = output;
      scrambleTarget.dataset.text = output;
      frame += 1;

      if (frame <= maxFrames) {
        window.requestAnimationFrame(scramble);
        return;
      }

      scrambleTarget.textContent = finalText;
      scrambleTarget.dataset.text = finalText;
      scrambleTarget.classList.add("glitch-complete");
      window.setTimeout(startScramble, 4000);
    };

    scramble();
  };

  if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
    scrambleTarget.textContent = finalText;
    scrambleTarget.dataset.text = finalText;
  } else {
    startScramble();
  }
}

const escapeHtml = (value) => value.replace(/[&<>'"]/g, (character) => ({
  "&": "&amp;",
  "<": "&lt;",
  ">": "&gt;",
  "'": "&#39;",
  "\"": "&quot;"
}[character]));

const sections = {
  home: { title: "Home", path: "/" },
  whoami: { title: "Whoami", path: "/whoami/" },
  career: { title: "Career Timeline", path: "/career/" },
  trainings: { title: "Trainings", path: "/trainings/" },
  certifications: { title: "Certifications", path: "/certifications/" },
  talks: { title: "Speakership and Mentorship", path: "/speakership-mentorship/" },
  ctf: { title: "CTF Participation and Writeups", path: "/ctf-writeups/" },
  soc: { title: "SOC Notes", path: "/soc-notes/" },
  cheatsheets: { title: "Cheatsheets", path: "/cheatsheets/" },
  recognitions: { title: "Recognitions", path: "/recognitions/" },
  conferences: { title: "Conferences Attended", path: "/conferences/" },
  misc: { title: "Misc", path: "/misc/" }
};

const aliases = {
  cert: "certifications",
  certs: "certifications",
  training: "trainings",
  speakership: "talks",
  mentorship: "talks",
  "speakership-and-mentorship": "talks",
  writeups: "ctf",
  "ctf-writeups": "ctf",
  "ctf-participation-and-writeups": "ctf",
  notes: "soc",
  "soc-notes": "soc",
  sheets: "cheatsheets",
  recognition: "recognitions",
  conference: "conferences",
  conf: "conferences",
  "career-timeline": "career"
};

const certifications = [
  "SIREN Engr.",
  "CompTIA Security+",
  "eJPT",
  "CCTA",
  "CCTH",
  "CCEP",
  "ISC2 Certified in Cybersecurity"
];

const normalizePageName = (value) => value
  .trim()
  .toLowerCase()
  .replace(/^\/+|\/+$/g, "")
  .replace(/\s+/g, "-");

const resolveSection = (target) => {
  const normalized = normalizePageName(target);
  const key = aliases[normalized] || normalized;

  if (sections[key]) return sections[key];

  return Object.values(sections).find((item) => normalizePageName(item.title) === normalized);
};

const sectionList = () => Object.entries(sections)
  .map(([key, item]) => `<button type="button" class="terminal-link" data-terminal-command="cd ${key}">${item.title}</button>`)
  .join("");

const huntsmanAscii = [
  " _  _ _  _ _  _ _____ ___ __  __   _   _  _",
  "| || | || | |\\ | |_   _/ __|  \\/  | /_\\ | \\ |",
  "| __ | || |  \\| | | | \\__ \\ |\\/| |/ _ \\| .` |",
  "|_||_|\\__/|_|\\_| |_| |___/_|  |_/_/ \\_\\_|\\_|"
].join("\n");

document.querySelectorAll("[data-terminal]").forEach((terminal) => {
  const output = terminal.querySelector("[data-terminal-output]");
  const form = terminal.querySelector("[data-terminal-form]");
  const input = form?.querySelector("input");

  if (!output || !form || !input) return;

  const print = (html) => {
    const line = document.createElement("div");
    line.className = "terminal-line";
    line.innerHTML = html;
    output.appendChild(line);
    terminal.classList.add("has-output");
    output.scrollTop = output.scrollHeight;
  };

  const runCommand = (rawCommand) => {
    const command = rawCommand.trim().toLowerCase();
    if (!command) return;

    if (command === "clear") {
      output.innerHTML = "";
      terminal.classList.remove("has-output");
      return;
    }

    print(`<span>$</span> ${escapeHtml(command)}`);

    if (command === "help") {
      print("Commands: whoami, ls, cd &lt;page&gt;, cert, cat flag.txt, security, clear.");
      return;
    }

    if (command === "whoami") {
      print(`<pre class="terminal-ascii">${huntsmanAscii}</pre><strong>Huntsman</strong><br><span>hacking since 2007</span>`);
      return;
    }

    if (command === "ls" || command === "sections") {
      print("Available pages:");
      print(`<div class="terminal-command-grid">${sectionList()}</div>`);
      return;
    }

    if (command === "cert" || command === "certs") {
      print(`<strong>Certifications</strong><br>${certifications.map((item) => escapeHtml(item)).join("<br>")}`);
      return;
    }

    if (command === "cat flag.txt") {
      print("<strong>hunt{p0w3r_b3l0ngs_2d_p30pl3_th4t_t4k3_it}</strong>");
      return;
    }

    if (command === "security") {
      print("Publishing mode: public-safe. No .env files, private keys, tokens, customer data, internal screenshots, tenant IDs, or live infrastructure details.");
      return;
    }

    const directoryCommand = command.match(/^(?:cd|open)\s+(.+)$/);
    if (directoryCommand) {
      const target = directoryCommand[1];
      const item = resolveSection(target);

      if (item) {
        window.location.assign(item.path);
        return;
      }

      print(`No page named <strong>${escapeHtml(target)}</strong>. Run <strong>ls</strong> to list pages.`);
      return;
    }

    const item = resolveSection(command);
    if (item) {
      print(`<strong>${item.title}</strong><br>Run <strong>cd ${normalizePageName(item.title)}</strong> to open this page.`);
      return;
    }

    print(`Command not found: <strong>${escapeHtml(command)}</strong>. Type <strong>help</strong>.`);
  };

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    runCommand(input.value);
    input.value = "";
  });

  output.addEventListener("click", (event) => {
    const button = event.target.closest("[data-terminal-command]");
    if (!button) return;
    runCommand(button.dataset.terminalCommand);
  });
});

document.querySelectorAll("[data-carousel]").forEach((carousel) => {
  const slides = [...carousel.querySelectorAll("[data-carousel-slide]")];
  const previous = carousel.querySelector("[data-carousel-prev]");
  const next = carousel.querySelector("[data-carousel-next]");
  const status = carousel.querySelector("[data-carousel-status]");
  let activeIndex = 0;

  if (slides.length === 0 || !previous || !next || !status) return;

  const render = () => {
    slides.forEach((slide, index) => {
      slide.hidden = index !== activeIndex;
    });
    status.textContent = `${activeIndex + 1} / ${slides.length}`;
  };

  previous.addEventListener("click", () => {
    activeIndex = (activeIndex - 1 + slides.length) % slides.length;
    render();
  });

  next.addEventListener("click", () => {
    activeIndex = (activeIndex + 1) % slides.length;
    render();
  });

  render();
});
