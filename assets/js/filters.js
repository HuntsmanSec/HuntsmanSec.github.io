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

const scrambleTarget = document.querySelector("[data-scramble]");

if (scrambleTarget) {
  const finalText = scrambleTarget.dataset.scramble;
  const glyphs = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_#$%";
  let frame = 0;
  const maxFrames = finalText.length * 5;

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
  };

  scramble();
}

const terminal = document.querySelector("[data-terminal]");

if (terminal) {
  const output = terminal.querySelector("[data-terminal-output]");
  const form = terminal.querySelector("[data-terminal-form]");
  const input = form.querySelector("input");
  const sections = {
    career: {
      title: "Career Timeline",
      body: "Roles, milestones, tools, and public-safe professional growth notes.",
      path: "/career/"
    },
    trainings: {
      title: "Trainings",
      body: "Courses, labs, workshops, and learning paths.",
      path: "/trainings/"
    },
    certifications: {
      title: "Certifications",
      body: "Credentials, verification links, and exam domains.",
      path: "/certifications/"
    },
    talks: {
      title: "Speakership and Mentorship",
      body: "Talks, mentorship sessions, community support, and shared learning.",
      path: "/speakership-mentorship/"
    },
    mentorship: {
      title: "Speakership and Mentorship",
      body: "Talks, mentorship sessions, community support, and shared learning.",
      path: "/speakership-mentorship/"
    },
    ctf: {
      title: "CTF Participation and Writeups",
      body: "Challenge walkthroughs, methods, tools, and lessons learned.",
      path: "/ctf-writeups/"
    },
    soc: {
      title: "SOC Notes",
      body: "Alert triage, investigation workflows, detection notes, and analyst references.",
      path: "/soc-notes/"
    },
    cheatsheets: {
      title: "Cheatsheets",
      body: "Fast references for commands, logs, filters, tools, and queries.",
      path: "/cheatsheets/"
    },
    recognitions: {
      title: "Recognitions",
      body: "Awards, acknowledgements, public milestones, and community recognition.",
      path: "/recognitions/"
    },
    conferences: {
      title: "Conferences Attended",
      body: "Events, sessions, and takeaways from security conferences.",
      path: "/conferences/"
    },
    misc: {
      title: "Misc",
      body: "Home lab ideas, reading lists, experiments, and small security projects.",
      path: "/misc/"
    }
  };

  const aliases = {
    certs: "certifications",
    training: "trainings",
    speakership: "talks",
    writeups: "ctf",
    notes: "soc",
    sheets: "cheatsheets",
    conf: "conferences",
    conference: "conferences",
    recognition: "recognitions"
  };

  const print = (html) => {
    const line = document.createElement("div");
    line.className = "terminal-line";
    line.innerHTML = html;
    output.appendChild(line);
    output.scrollTop = output.scrollHeight;
  };

  const sectionList = () => Object.entries(sections)
    .filter(([key]) => !["mentorship"].includes(key))
    .map(([key, item]) => `<button type="button" class="terminal-link" data-terminal-command="${key}">${item.title}</button>`)
    .join("");

  const showSection = (key) => {
    const normalized = aliases[key] || key;
    const item = sections[normalized];

    if (!item) {
      print(`Command not found: <strong>${key}</strong>. Type <strong>help</strong>.`);
      return;
    }

    print(`<strong>${item.title}</strong><br>${item.body}<br><a href="${item.path}">open ${item.path}</a>`);
  };

  const runCommand = (rawCommand) => {
    const command = rawCommand.trim().toLowerCase();
    if (!command) return;

    print(`<span>$</span> ${command}`);

    if (command === "clear") {
      output.innerHTML = "";
      return;
    }

    if (command === "help") {
      print("Commands: help, whoami, sections, security, clear, open &lt;section&gt;.");
      print(`<div class="terminal-command-grid">${sectionList()}</div>`);
      return;
    }

    if (command === "whoami") {
      print("<strong>HuntsmanSec</strong><br>Cybersecurity portfolio focused on SOC notes, detection learning, CTF practice, cheatsheets, talks, mentorship, and public-safe documentation.");
      return;
    }

    if (command === "sections" || command === "ls") {
      print(`<div class="terminal-command-grid">${sectionList()}</div>`);
      return;
    }

    if (command === "security") {
      print("Publishing mode: public-safe. No .env files, private keys, tokens, customer data, internal screenshots, tenant IDs, or live infrastructure details.");
      return;
    }

    if (command.startsWith("open ")) {
      const target = command.replace("open ", "").trim();
      const normalized = aliases[target] || target;
      const item = sections[normalized];
      if (item) {
        window.location.href = item.path;
        return;
      }
    }

    showSection(command);
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
}
