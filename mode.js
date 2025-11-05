// mode.js

export function boot({ registry, defaultType = 'person' } = {}) {
  const state = { type: null, filters: {} };

  const els = {
    typeBar:     document.getElementById('browse--types'),
    sidebar:     document.getElementById('filter-sidebar'),
    personPanel: document.getElementById('personResults'),
    eventPanel:  document.getElementById('eventResults'),
  };

  const readTypeFromUrl = () =>
    new URLSearchParams(location.search).get('type') || defaultType;

  const writeTypeToUrl = (type, replace = false) => {
    const qs = new URLSearchParams(location.search);
    qs.set('type', type);
    const url = `${location.pathname}?${qs.toString()}`;
    replace ? history.replaceState({ type }, '', url)
            : history.pushState({ type }, '', url);
  };

  const setActiveTypeButton = (type) => {
    els.typeBar?.querySelectorAll('button[data-type]')?.forEach(btn => {
      btn.classList.toggle('active', btn.dataset.type === type);
    });
  };

  const togglePanels = (type) => {
    if (els.personPanel) els.personPanel.classList.toggle('d-none', type !== 'person');
    if (els.eventPanel)  els.eventPanel.classList.toggle('d-none',  type !== 'event');
  };
 


  const wireSidebarChrome = (root, state, runSearch) => {    root.addEventListener('click', (e) => {
    console.log('Sidebar clicked, mode.js');  
    const btn = e.target.closest('.collapse-toggle');
      if (!btn) return;
      const tgt = document.getElementById(btn.dataset.target);
      if (!tgt) return;
      tgt.classList.toggle('collapsed');
      const span = btn.querySelector('span');
      if (span) span.textContent = tgt.classList.contains('collapsed') ? '+' : '−';
    });
    // SECTION CLEAR BUTTONS
    root.addEventListener('click', (e) => {
      const clearBtn = e.target.closest('.clear-section-btn');
      if (!clearBtn) return;
      e.preventDefault();
      e.stopPropagation();
      console.log('Clear section button clicked, mode.js');
      // fire a custom event the active mode can catch
      const section = clearBtn.dataset.section;
      root.dispatchEvent(new CustomEvent('clearSection', {
        detail: { section },
        bubbles: true
      }));
    });



        // // CLEAR ALL BUTTON
        // root.addEventListener('click', (e) => {
        //   const clearAll = e.target.closest('#clearAllFilters');
        //   if (!clearAll) return;
        //   e.preventDefault();
        //   e.stopPropagation();

        //   // Clear all inputs in sidebar
        //   root.querySelectorAll('input[type="checkbox"], input[type="radio"]').forEach(cb => cb.checked = false);
        //   root.querySelectorAll('input[type="text"], select').forEach(el => el.value = '');

        //   // Reset state.filters
        //   state.filters = {};
        //   console.log('***Filters after clearing all:', state.filters);
        //   // Clear URL params but preserve `type`
        //   const url = new URL(location);
        //   const type = url.searchParams.get('type');
        //   url.search = type ? `type=${type}` : '';
        //   history.replaceState({}, '', url);

        //   runSearch?.(); // refresh results
        // });
  };

  async function mount(type, { fromPopstate = false } = {}) {
    if (!registry[type]) type = defaultType;
    state.type = type;

    togglePanels(type);
    
    const runSearch = async () => {
      if (!mode.fetch || !mode.render) return;
      const rows = await mode.fetch(state);
      mode.render(rows, state);
    };

    const mode = registry[type];
    els.sidebar.innerHTML = mode.sidebar?.(state) ?? '';
    wireSidebarChrome(els.sidebar, state, runSearch);


    mode.bind?.(els.sidebar, state, runSearch);

    setActiveTypeButton(type);
    if (!fromPopstate) writeTypeToUrl(type);

    runSearch();
  }

  els.typeBar?.addEventListener('click', (e) => {
    const btn = e.target.closest('button[data-type]');
    if (!btn) return;
    mount(btn.dataset.type);
  });

  window.addEventListener('popstate', () => {
    mount(readTypeFromUrl(), { fromPopstate: true });
  });

  // First paint (respect current URL)
  mount(readTypeFromUrl(), { fromPopstate: true });
}
