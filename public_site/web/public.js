(() => {
  const supabase = 'https://dddriininznavwrsrgww.supabase.co';
  const key = 'sb_publishable_4azID8YOd0M1UcjqdIi_cw_sdnTi39E';
  const headers = { apikey: key, Authorization: `Bearer ${key}` };

  const menuButton = document.querySelector('.menu-toggle');
  const menu = document.querySelector('#mobile-menu');
  const menuBackdrop = document.querySelector('.mobile-menu-backdrop');
  const setMenuOpen = (open) => {
    menu.toggleAttribute('hidden', !open);
    menuBackdrop.toggleAttribute('hidden', !open);
    menuButton.setAttribute('aria-expanded', String(open));
    menuButton.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
  };
  menuButton?.addEventListener('click', () => setMenuOpen(menu.hasAttribute('hidden')));
  menuBackdrop?.addEventListener('click', () => setMenuOpen(false));
  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && !menu.hasAttribute('hidden')) setMenuOpen(false);
  });
  const searchButton = document.querySelector('.search-control');
  const searchForm = document.querySelector('.header-search');
  searchButton?.addEventListener('click', () => {
    const opening = !document.querySelector('.site-header').classList.contains('search-open');
    document.querySelector('.site-header').classList.toggle('search-open', opening);
    searchForm.inert = !opening;
    searchForm.setAttribute('aria-hidden', String(!opening));
    document.querySelector('.desktop-nav').inert = opening;
    searchButton.setAttribute('aria-label', opening ? 'Close search' : 'Search products');
    searchButton.querySelector('path').setAttribute('d', opening
      ? 'M19 6.41 17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z'
      : 'M15.5 14h-.79l-.28-.27A6.47 6.47 0 0 0 16 9.5 6.5 6.5 0 1 0 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0A4.5 4.5 0 1 1 9.5 5a4.5 4.5 0 0 1 0 9z');
    if (opening) searchForm.querySelector('input').focus();
  });

  const pathname = location.pathname.replace(/\/$/, '') || '/';
  document.body.dataset.page = pathname;
  if (pathname === '/') {
    document.querySelector('.home-nav')?.setAttribute('aria-current', 'page');
  }

  for (const anchor of document.querySelectorAll('[data-social-key]')) {
    const value = window.KALASTHALI_SOCIAL?.[anchor.dataset.socialKey];
    if (value && /^https?:\/\//i.test(value)) {
      anchor.href = value;
      anchor.target = '_blank';
      anchor.rel = 'noopener noreferrer';
    } else {
      anchor.hidden = true;
    }
  }

  try {
    const sessionKey = Object.keys(localStorage).find((value) =>
      /^sb-.*-auth-token$/.test(value));
    const auth = sessionKey && JSON.parse(localStorage.getItem(sessionKey));
    const user = auth?.user;
    if (user) {
      const firstName = user.user_metadata?.first_name ||
        user.user_metadata?.firstName || user.user_metadata?.name ||
        user.email?.split('@')[0] || 'ACCOUNT';
      document.querySelector('.account-label').textContent = firstName.split(' ')[0].toUpperCase();
      document.querySelector('.mobile-account').textContent = firstName.toUpperCase();
      if (['admin.kalasthali@gmail.com', 'nisharohilla651@gmail.com']
        .includes(user.email?.toLowerCase())) {
        document.querySelectorAll('.admin-control, .mobile-admin')
          .forEach((item) => { item.hidden = false; });
      }
    }
  } catch (_) {
    // A missing or expired local session leaves the account link as Log In.
  }

  const policy = document.querySelector('[data-policy-slug]');
  if (policy) {
    document.querySelector('#policy-updated').textContent =
      new Intl.DateTimeFormat('en-GB').format(new Date());
    const slug = policy.dataset.policySlug;
    fetch(`${supabase}/rest/v1/site_policies?slug=eq.${encodeURIComponent(slug)}&select=title,content,updated_at&limit=1`,
      { headers })
      .then((response) => {
        if (!response.ok) throw new Error(`Policy request failed: ${response.status}`);
        return response.json();
      })
      .then(([row]) => {
        if (!row) return;
        policy.querySelector('.policy-title').textContent = row.title;
        const content = policy.querySelector('#policy-content');
        content.replaceChildren(...row.content.trim().split('\n\n').map((section) => {
          const paragraph = document.createElement('p');
          paragraph.textContent = section;
          return paragraph;
        }));
        if (row.updated_at) {
          document.querySelector('#policy-updated').textContent =
            new Intl.DateTimeFormat('en-GB').format(new Date(row.updated_at));
        }
      })
      .catch(() => {});
  }

  const carousel = document.querySelector('#popular-products');
  if (!carousel) return;
  fetch(`${supabase}/rest/v1/products?is_popular=eq.true&select=code,name,description,type,is_sold_out&order=code.asc`,
    { headers })
    .then((response) => {
      if (!response.ok) throw new Error(`Products request failed: ${response.status}`);
      return response.json();
    })
    .then((products) => {
      if (!products.length) {
        carousel.textContent = 'No popular products available';
        return;
      }
      const dots = document.querySelector('#carousel-dots');
      let index = 0;
      let autoTimer;
      let resumeTimer;
      let scrollEndTimer;
      let manualScroll = false;
      const cards = products.map((product) => {
        const card = document.createElement('article');
        card.className = 'carousel-card';
        const imageLink = document.createElement('a');
        imageLink.className = 'carousel-image';
        imageLink.href = `/product?code=${encodeURIComponent(product.code)}`;
        const image = document.createElement('img');
        image.src = `${supabase}/storage/v1/object/public/product_images/${encodeURIComponent(product.code)}/thumbnail.webp`;
        image.alt = product.name;
        image.loading = 'lazy';
        imageLink.append(image);
        const copy = document.createElement('div');
        copy.className = 'carousel-copy';
        const name = document.createElement('h3');
        name.textContent = product.name;
        const type = document.createElement('span');
        type.className = 'carousel-type';
        type.textContent = product.type || '';
        const description = document.createElement('p');
        description.textContent = product.description;
        const details = document.createElement('a');
        details.href = imageLink.href;
        details.textContent = 'ⓘ  More Info';
        const cart = document.createElement('a');
        cart.className = 'add-cart';
        cart.textContent = product.is_sold_out ? 'SOLD OUT' : 'Add to Cart';
        if (product.is_sold_out) {
          cart.setAttribute('aria-disabled', 'true');
          cart.removeAttribute('href');
        } else {
          cart.href = `/product?code=${encodeURIComponent(product.code)}&add=1`;
        }
        copy.append(name, type, description, details, cart);
        card.append(imageLink, copy);
        return card;
      });
      carousel.replaceChildren(...cards);
      const update = () => {
        const first = Math.max(0, Math.min(index - 2, cards.length - 5));
        const visible = Array.from({ length: Math.min(cards.length, 5) }, (_, offset) => first + offset);
        dots.replaceChildren(...visible.map((number) => {
          const dot = document.createElement('button');
          dot.type = 'button';
          dot.setAttribute('aria-label', `Go to product ${number + 1}`);
          dot.className = number === index ? 'active' : '';
          if (number === index) dot.setAttribute('aria-current', 'true');
          dot.addEventListener('click', () => move(number, true));
          return dot;
        }));
      };
      const scheduleAuto = (delay = 30000) => {
        clearTimeout(autoTimer);
        if (cards.length < 2 || matchMedia('(prefers-reduced-motion: reduce)').matches) return;
        autoTimer = setTimeout(() => {
          if (!document.hidden) move(index + 1);
          scheduleAuto();
        }, delay);
      };
      const pauseForManualScroll = () => {
        manualScroll = true;
        clearTimeout(autoTimer);
        clearTimeout(resumeTimer);
        clearTimeout(scrollEndTimer);
        scrollEndTimer = setTimeout(() => {
          manualScroll = false;
          resumeTimer = setTimeout(() => scheduleAuto(0), 15000);
        }, 200);
      };
      const move = (number, manual = false) => {
        if (manual) pauseForManualScroll();
        index = (number + cards.length) % cards.length;
        carousel.scrollTo({
          left: cards[index].offsetLeft - cards[0].offsetLeft +
            cards[index].offsetWidth / 2 - carousel.clientWidth / 2 +
            parseFloat(getComputedStyle(carousel).paddingLeft),
          behavior: 'smooth',
        });
        update();
      };
      document.querySelector('.carousel-arrow.prev')?.addEventListener('click',
        () => move(index - 1, true));
      document.querySelector('.carousel-arrow.next')?.addEventListener('click',
        () => move(index + 1, true));
      const updateFromScroll = () => {
        const center = carousel.scrollLeft + carousel.clientWidth / 2;
        let nearest = 0;
        let distance = Infinity;
        cards.forEach((card, number) => {
          const cardCenter = card.offsetLeft - cards[0].offsetLeft +
            parseFloat(getComputedStyle(carousel).paddingLeft) + card.offsetWidth / 2;
          const nextDistance = Math.abs(cardCenter - center);
          if (nextDistance < distance) { distance = nextDistance; nearest = number; }
        });
        if (nearest !== index) { index = nearest; update(); }
        if (manualScroll) pauseForManualScroll();
      };
      carousel.addEventListener('scroll', updateFromScroll, { passive: true });
      carousel.addEventListener('pointerdown', pauseForManualScroll, { passive: true });
      carousel.addEventListener('wheel', pauseForManualScroll, { passive: true });
      carousel.addEventListener('keydown', (event) => {
        if (event.key === 'ArrowLeft' || event.key === 'ArrowRight') pauseForManualScroll();
      });
      update();
      scheduleAuto();
    })
    .catch(() => { carousel.textContent = 'New arrivals are temporarily unavailable.'; });
})();
