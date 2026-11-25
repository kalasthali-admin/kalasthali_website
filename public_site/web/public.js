(() => {
  const supabase = 'https://dddriininznavwrsrgww.supabase.co';
  const key = 'sb_publishable_4azID8YOd0M1UcjqdIi_cw_sdnTi39E';
  const headers = { apikey: key, Authorization: `Bearer ${key}` };

  const menuButton = document.querySelector('.menu-toggle');
  const menu = document.querySelector('#mobile-menu');
  menuButton?.addEventListener('click', () => {
    const open = menu.hasAttribute('hidden');
    menu.toggleAttribute('hidden', !open);
    menuButton.setAttribute('aria-expanded', String(open));
    menuButton.setAttribute('aria-label', open ? 'Close menu' : 'Open menu');
  });
  const searchButton = document.querySelector('.search-control');
  const searchForm = document.querySelector('.header-search');
  searchButton?.addEventListener('click', () => {
    const opening = searchForm.hasAttribute('hidden');
    searchForm.toggleAttribute('hidden', !opening);
    document.querySelector('.desktop-nav').hidden = opening;
    searchButton.setAttribute('aria-label', opening ? 'Close search' : 'Search products');
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
  fetch(`${supabase}/rest/v1/products?is_popular=eq.true&select=code,name,description,is_sold_out&order=code.asc`,
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
        const description = document.createElement('p');
        description.textContent = product.description;
        const details = document.createElement('a');
        details.href = imageLink.href;
        details.textContent = 'ⓘ  More Info';
        const cart = document.createElement('a');
        cart.className = 'add-cart';
        cart.textContent = product.is_sold_out ? 'SOLD OUT' : '🛒  Add to Cart';
        if (product.is_sold_out) {
          cart.setAttribute('aria-disabled', 'true');
          cart.removeAttribute('href');
        } else {
          cart.href = `/product?code=${encodeURIComponent(product.code)}&add=1`;
        }
        copy.append(name, description, details, cart);
        card.append(imageLink, copy);
        return card;
      });
      carousel.replaceChildren(...cards);
      const update = () => {
        dots.replaceChildren(...cards.map((_, number) => {
          const dot = document.createElement('button');
          dot.type = 'button';
          dot.setAttribute('aria-label', `Go to product ${number + 1}`);
          dot.className = number === index ? 'active' : '';
          dot.addEventListener('click', () => move(number));
          return dot;
        }));
      };
      const move = (number) => {
        index = (number + cards.length) % cards.length;
        carousel.scrollTo({ left: cards[index].offsetLeft - cards[0].offsetLeft,
          behavior: 'smooth' });
        update();
      };
      document.querySelector('.carousel-arrow.prev')?.addEventListener('click',
        () => move(index - 1));
      document.querySelector('.carousel-arrow.next')?.addEventListener('click',
        () => move(index + 1));
      update();
      if (cards.length > 1 && !matchMedia('(prefers-reduced-motion: reduce)').matches) {
        setInterval(() => { if (!document.hidden) move(index + 1); }, 2000);
      }
    })
    .catch(() => { carousel.textContent = 'New arrivals are temporarily unavailable.'; });
})();
