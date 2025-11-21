// Event mode for SPEAR application: User requestsed filters for event factoids: by associated persons, event keywords, places, occupations, gender, uncertainty, and sources.
import {
  getEventKeywords,
  getRelationshipOptions,
  getPlaceOptions,
  getOccupationOptions,
  renderKeywordList
} from '../menu.js';

import { renderKeywordPrettyList } from '../list.js';
import persons from '../event/person.json' with { type: 'json' };
import { cleanPunctuationSpacing } from '../utils/cleanUi.js';
// Use your existing fetcher that already works for event factoids
// (adjust the path if your fetcher lives elsewhere)
// import { fetchEventFactoids } from '../search.js';
import { fetchEventFactoids } from '../event/search.js';


function writeFilterParamsToUrl(filterState) {
  // Preserve existing params like ?type=event, only replace filter params
  const url = new URL(location.href);
  const keys = ['nameSearch','gender','uncertainty','source','occupation','event','place'];
  keys.forEach(k => url.searchParams.delete(k));
  if (filterState.name && filterState.name.trim()) {
    url.searchParams.set('nameSearch', filterState.name.trim());
  }
  for (const uri of filterState.selectedGenderKeywords)      url.searchParams.append('gender', uri);
  if (filterState.uncertainty)                                url.searchParams.set('uncertainty', filterState.uncertainty);
  for (const uri of filterState.selectedSourceKeywords)       url.searchParams.append('source', uri);
  for (const uri of filterState.selectedOccupationKeywords)   url.searchParams.append('occupation', uri);
  for (const uri of filterState.selectedEventKeywords)        url.searchParams.append('event', uri);
  for (const uri of filterState.selectedPlaceKeywords)        url.searchParams.append('place', uri);
  history.replaceState({}, '', url);
}
// put this near your fetch() ??
const str = (x) => {
  if (x == null) return '';
  if (typeof x === 'object' && 'value' in x) return (x.value ?? '').toString();
  return ('' + x);
};

export default {
  id: 'event',

  sidebar(state) {
    return `
      <div class="filter-sidebar" id="filter-sidebar">
        <div className="filter-section"><div class="filter-title d-flex justify-content-between align-items-right" style="justify-items: right;">                        
          <button type="button" class="btn btn-outline-dark" data-type="person" id="clearFiltersBtn">
              Remove Filters/Show All Event Factoids
          </button>
        </div>
      </div>
      <!-- Source Filter -->
      <div class="filter-section">
        <div class="filter-title d-flex justify-content-between align-items-center">
                Sources
                <div class="d-flex gap-2">
                  <button class="clear-section-btn" data-section="source" title="Clear source filter">
                    <span>×</span>
                  </button>
                  <button class="collapse-toggle" data-target="source-select">
                    <span>−</span>
                  </button>
                </div>
              </div>
              <div class="filter-content" id="source-select">
                <div class="checkbox-group" id="sourceSelect">
                    <label><input class="me-1" type="checkbox" name="source" value="" data-all checked /> All sources</label>
                    <label><input class="me-1" type="checkbox" name="source" value="https://spear-prosop.org/letters-severus" checked /> Letters of Severus of Antioch</label>
                    <label><input class="me-1" type="checkbox" name="source" value="https://spear-prosop.org/lives-eastern-saints" checked /> Lives of the Eastern Saints</label>
                    <label><input class="me-1" type="checkbox" name="source" value="https://spear-prosop.org/chronicle-edessa" checked /> Chronicle of Edessa</label>
                </div>
            </div>
          </div>
          <!-- Source Filter -->
          <div class="filter-section">
                <div class="filter-title d-flex justify-content-between align-items-center">
                  Event Concepts
                  <div class="d-flex gap-2">
                    <button class="clear-section-btn" data-section="event" title="Clear event filter">
                      <span>×</span>
                    </button>
                    <button class="collapse-toggle" data-target="events-filter">
                      <span>−</span>
                    </button>
                  </div>
                </div>
                <div class="filter-content" id="events-filter">
                  <div class="filter-control">
                    <label for="event-multiselect">Select events:</label>
                    <div class="multiselect-container">
                      <input type="text" id="event-search" class="form-control form-control-sm"
                        placeholder="Type to search events..." autocomplete="off" />
                      <div class="multiselect-dropdown" id="event-dropdown">
                      </div>
                      <div class="selected-items" id="event-selected">
                        <!-- Selected items will appear here -->
                      </div>
                    </div>
                  </div>
                
                  <div id="eventKeywordList" class="keywordList">
                    <ul id="eventKeywordItems"></ul>
                  </div>
                </div>
              </div>
                      <div class="filter-section">
                <div class="filter-title d-flex justify-content-between align-items-center">
                  Associated Places
                  <div class="d-flex gap-2">
                    <button class="clear-section-btn" data-section="place" title="Clear place filter">
                      <span>×</span>
                    </button>
                    <button class="collapse-toggle" data-target="place-filter">
                      <span>−</span>
                    </button>
                  </div>
                </div>
        
                <div class="filter-content" id="place-filter">
                  <div class="filter-control">
                    <label for="place-multiselect">Select place:</label>
                    <div class="multiselect-container">
                      <input type="text" id="place-search" class="form-control form-control-sm"
                        placeholder="Type to search places..." autocomplete="off" />
                      <div class="multiselect-dropdown" id="place-dropdown">
                      </div>
                      <div class="selected-items" id="place-selected">
                        <!-- Selected items will appear here -->
                      </div>
                    </div>
                  </div>
                  <div id="placeKeywordList" class="keywordList">
                    <ul id="placeKeywordItems"></ul>
                  </div>
                </div>
        </div>
              <h5 class="filter-title">Associated Persons</h5>
              <!-- Names Filter -->
            
              <div class="filter-section">
                <div class="filter-title d-flex justify-content-between align-items-center">
                  Names
                  <div class="d-flex gap-2">
                    <button class="clear-section-btn" data-section="names" title="Clear names filter">
                      <span>×</span>
                    </button>
                    <button class="collapse-toggle" data-target="names-filter">
                      <span>−</span>
                    </button>
                  </div>
                </div>
                <div class="filter-content" id="names-filter">
                  <div class="filter-control">
                    <label for="name-search">Search by name:</label>
                    <input type="text" id="name-search" class="form-control form-control-sm"
                      placeholder="Enter name..." />
                  </div>
                                 <!-- Letter Filter -->
                <div id="browse--letter-filter" class="mb-3"></div>
                </div>
              </div>
               
              <!-- Gender Filter use checkboxes for multiselection capability -->
    
              <!-- <div class="filter-section">
                <div class="filter-title d-flex justify-content-between align-items-center">
                  Gender
                  <div class="d-flex gap-2">
                    <button class="clear-section-btn" data-section="gender" title="Clear gender filter">
                      <span>×</span>
                    </button>
                    <button class="collapse-toggle" data-target="gender-filter">
                      <span>−</span>
                    </button>
                  </div>
                </div>
                <div class="filter-content" id="gender-filter">
                  <div class="radio-group">
                    <label>
                      <input class="me-1" type="radio" name="gender" value="" checked />
                      All genders
                    </label>
                    <label>
                      <input class="me-1" type="radio" name="gender" value="men" />
                      Men
                    </label>
                    <label>
                      <input class="me-1" type="radio" name="gender" value="women" />
                      Women
                    </label>
                    <label>
                      <input class="me-1" type="radio" name="gender" value="eunuchs" />
                      Eunuchs
                    </label>
                  </div>
                </div>
                              <div class="filter-section">
   
      </div>
              </div> -->
            <div class="filter-section">
              <div class="filter-title d-flex justify-content-between align-items-center">
                Gender
                <div class="d-flex gap-2">
                  <button class="clear-section-btn" data-section="gender" title="Clear gender filter">
                    <span>×</span>
                  </button>
                  <button class="collapse-toggle" data-target="gender-select">
                    <span>−</span>
                  </button>
                </div>
              </div>

              <div class="filter-content" id="gender-select">
            <div class="checkbox-group" id="genderSelect">
              <label><input class="me-1" type="checkbox" name="gender" value="http://syriaca.org/taxonomy/men" /> Men</label>
              <label><input class="me-1" type="checkbox" name="gender" value="http://syriaca.org/taxonomy/women" /> Women</label>
              <label><input class="me-1" type="checkbox" name="gender" value="http://syriaca.org/taxonomy/eunuchs" /> Eunuchs</label>
            </div>
          </div>
          </div>
              <!-- Events Filter -->
          <div class="filter-section">
                     <div class="filter-title d-flex justify-content-between align-items-center">
                  Occupations
                  <div class="d-flex gap-2">
                    <button class="clear-section-btn" data-section="occupations" title="Clear occupations filter">
                      <span>×</span>
                    </button>
                    <button class="collapse-toggle" data-target="occupations-filter">
                      <span>−</span>
                    </button>
                  </div>
                </div>
                        <div class="filter-content" id="occupations-filter">
                  <div class="filter-control">
                    <label for="occupation-multiselect">Select occupations:</label>
                    <div class="multiselect-container">
                      <input type="text" id="occupation-search" class="form-control form-control-sm"
                        placeholder="Type to search occupations..." autocomplete="off" />
                      <div class="multiselect-dropdown" id="occupation-dropdown">

                      </div>
                      <div class="selected-items" id="occupation-selected">
                        <!-- Selected items will appear here -->
                      </div>
                    </div>
                  </div>

        <div id="occupationKeywordList" class="keywordList">
          <ul id="occupationKeywordItems" class="keywordItems"></ul>
        </div></div>
      
      </div>




              <!-- Uncertainty Filter -->
              <div class="filter-section">
                <div class="filter-title d-flex justify-content-between align-items-center">
                  Uncertainty
                  <div class="d-flex gap-2">
                    <button class="clear-section-btn" data-section="uncertainty" title="Clear uncertainty filter">
                      <span>×</span>
                    </button>
                    <button class="collapse-toggle" data-target="uncertainty-filter">
                      <span>−</span>
                    </button>
                  </div>
                </div>
                <div class="filter-content" id="uncertainty-filter">
                  <div class="filter-control">
   <div class="checkbox-group" id="uncertaintySelect">
    <label>Exclude by uncertainty level:</label>
    <label><input class="me-1" type="checkbox" name="uncertainty" value="errata" /> Errata</label>
    <label><input class="me-1" type="checkbox" name="uncertainty" value="dubia" /> Dubia</label>
    <label><input class="me-1" type="checkbox" name="uncertainty" value="incerta" /> Incerta</label>
  </div>
                  </div>
                </div>
              </div>
              <div class="filter-content" id="uncertainty-filter">
  
 
</div>
            </div>
  </div>

    `;
  },

  bind(root, state, runSearch) {
    // one event-specific bucket in shared state
    state.filters.event ??= {
      name: '',
      personURIs: new Set(),
      persons: new Set(),
      events: new Set(),
      selectedEventKeywords:        new Set(),
      selectedRelationshipKeywords: new Set(),
      selectedGenderKeywords:       new Set(),
      // selectedUncertaintyKeywords:  new Set(), // not used directly; we store string in .uncertainty
      selectedPlaceKeywords:        new Set(),
      selectedOccupationKeywords:   new Set(),
      selectedSourceKeywords:       new Set([
        'https://spear-prosop.org/letters-severus',
        'https://spear-prosop.org/lives-eastern-saints',
        'https://spear-prosop.org/chronicle-edessa'
      ]),
      uncertainty: '' // CSV of errata,dubia,incerta to exclude
    };

    const s = state.filters.event;
    const params = new URLSearchParams(location.search);
    const initialName = params.get('nameSearch') || '';
    if (initialName) s.name = initialName;

    const nameInput = root.querySelector('#name-search');
    if (nameInput) {
      if (initialName) nameInput.value = initialName;

      // define debounce helper (or import it?)
      function debounce(fn, delay = 500) {
        let timeout;
        return (...args) => {
          clearTimeout(timeout);
          timeout = setTimeout(() => fn(...args), delay);
        };
      }

      // define debounced search callback
      const debouncedSearch = debounce((event) => {
        s.name = event.target.value.trim();
        writeFilterParamsToUrl(s);
        runSearch();
      }, 500);

      // attach listener
      nameInput.addEventListener('input', debouncedSearch);
    }
    // Helpers
    const toggleSet = (set, value) => set.has(value) ? set.delete(value) : set.add(value);

    // Gender
    root.querySelectorAll('input[name="gender"]').forEach(cb => {
      cb.addEventListener('change', () => {
        cb.checked ? s.selectedGenderKeywords.add(cb.value) : s.selectedGenderKeywords.delete(cb.value);
        writeFilterParamsToUrl(s);
        runSearch();
      });
    });

    // Uncertainty (collect checked values into CSV to exclude)
    root.querySelectorAll('input[name="uncertainty"]').forEach(cb => {
      cb.addEventListener('change', () => {
        const chosen = [...root.querySelectorAll('input[name="uncertainty"]:checked')].map(i => i.value);
        s.uncertainty = chosen.join(',');
        writeFilterParamsToUrl(s);
        runSearch();
      });
    });

    // Sources with "Include All"
    const srcBox  = root.querySelector('#sourceSelect');
    if (srcBox) {
      const all    = srcBox.querySelector('input[data-all]');
      const specs  = [...srcBox.querySelectorAll('input[name="source"]:not([data-all])')];
      const ALL    = specs.map(cb => cb.value);

      // initialize from defaults (checked in markup)
      s.selectedSourceKeywords = new Set(ALL);

      srcBox.addEventListener('change', (e) => {
        const t = e.target;
        if (t.matches('[data-all]')) {
          if (t.checked) {
            specs.forEach(cb => cb.checked = true);
            s.selectedSourceKeywords = new Set(ALL);
          }
        } else if (t.name === 'source') {
          t.checked ? s.selectedSourceKeywords.add(t.value) : s.selectedSourceKeywords.delete(t.value);
          all.checked = ALL.every(v => s.selectedSourceKeywords.has(v));
        }
        writeFilterParamsToUrl(s);
        runSearch();
      });
    }

    // Keyword lists (using your helpers; they target the IDs we render)
    const wireSearchFilter = (inputId, listSelector) => {
      const input = root.querySelector(`#${inputId}`);
      if (!input) return;
      input.addEventListener('input', () => {
        const filter = input.value.toLowerCase();
        root.querySelectorAll(`${listSelector} li`).forEach(li => {
          li.style.display = li.textContent.toLowerCase().includes(filter) ? 'block' : 'none';
        });
      });
    };

    renderKeywordPrettyList(getEventKeywords(), 'eventKeywordItems', 'eventKeywordList','keyword', 'keyword', (uri) => {
      toggleSet(s.selectedEventKeywords, uri);
      writeFilterParamsToUrl(s);
      runSearch();
    });


    renderKeywordList(getPlaceOptions(), 'placeKeywordItems', 'placeKeywordList', 'label', 'place', (uri) => {
      toggleSet(s.selectedPlaceKeywords, uri);
      writeFilterParamsToUrl(s);
      runSearch();
    });

    renderKeywordList(getRelationshipOptions(), 'relationshipKeywordItems', 'relationshipKeywordList', 'label', 'subject', (uri) => {
      toggleSet(s.selectedRelationshipKeywords, uri);
      writeFilterParamsToUrl(s);
      runSearch();
    });

    renderKeywordList(getOccupationOptions(), 'occupationKeywordItems', 'occupationKeywordList', 'label', 'occupation', (uri) => {
      toggleSet(s.selectedOccupationKeywords, uri);
      writeFilterParamsToUrl(s);
      runSearch();
    });

    wireSearchFilter('event-search',        '#eventKeywordItems');
    wireSearchFilter('relationship-search', '#relationshipKeywordItems');
    wireSearchFilter('place-search',        '#placeKeywordItems');
    wireSearchFilter('occupation-search',   '#occupationKeywordItems');

    // Clear section events, active
    root.addEventListener('clearSection', (e) => {
      const section = e.detail.section;
      const p = state.filters.event;
      console.log('Clear section event for:', section, p);
      if (!p) return;

      console.log('Clearing section:', section);
      if (section === 'names') {
        p.name = '';
        p.personURIs = [];
        p.persons = [];
      }
      
      // Handle uncertainty section specifically
      if (section === 'uncertainty') {
        p.uncertainty = '';
        const sec = root.querySelector(`.clear-section-btn[data-section="${section}"]`)?.closest('.filter-section');
        sec?.querySelectorAll('input[name="uncertainty"]').forEach(cb => (cb.checked = false));
        writeFilterParamsToUrl(p);
        runSearch();
        return;
      }
      
      const map = {
        names:        'name',
        gender:       'selectedGenderKeywords',
        source:       'selectedSourceKeywords',
        occupations:  'selectedOccupationKeywords',
        event:        'selectedEventKeywords',
        relationships:'selectedRelationshipKeywords',
        place:        'selectedPlaceKeywords'
      };

      const key = map[section];
      if (!key) return;
      const val = p[key];
      if (val instanceof Set) val.clear();
      else if (Array.isArray(val)) val.length = 0;
      else if (typeof val === 'string') p[key] = '';

      // visually reset that section
      const sec = root.querySelector(`.clear-section-btn[data-section="${section}"]`)?.closest('.filter-section');
      sec?.querySelectorAll('input[type="checkbox"], input[type="radio"]').forEach(cb => (cb.checked = false));
      sec?.querySelectorAll('input[type="text"], select').forEach(el => (el.value = ''));
      
      // Reset source checkboxes properly
      if (section === 'source') {
        const all = root.querySelector('#sourceSelect input[data-all]');
        if (all) all.checked = true;
        root.querySelectorAll('#sourceSelect input[name="source"]:not([data-all])').forEach(cb => (cb.checked = true));
        p.selectedSourceKeywords = new Set([
          'https://spear-prosop.org/letters-severus',
          'https://spear-prosop.org/lives-eastern-saints',
          'https://spear-prosop.org/chronicle-edessa'
        ]);
      }
      
      // Reset keyword lists
      sec?.querySelectorAll('.keywordList li.selected').forEach(li => li.classList.remove('selected'));

      writeFilterParamsToUrl(p);
      runSearch();
    });
    // Clear all
    root.querySelector('#clearFiltersBtn')?.addEventListener('click', () => {
      s.name = '';  
      s.personURIs = [];
      s.persons = [];
      s.events = [];
      s.selectedEventKeywords.clear();
      s.selectedRelationshipKeywords.clear();
      s.selectedPlaceKeywords.clear();
      s.selectedOccupationKeywords.clear();
      s.selectedGenderKeywords.clear();
      s.selectedSourceKeywords = new Set([
        'https://spear-prosop.org/letters-severus',
        'https://spear-prosop.org/lives-eastern-saints',
        'https://spear-prosop.org/chronicle-edessa'
      ]);
      s.uncertainty = '';

      // reset inputs visually
      root.querySelectorAll('input[name="gender"]').forEach(cb => (cb.checked = false));
      root.querySelectorAll('input[name="uncertainty"]').forEach(cb => (cb.checked = false));
      const all = root.querySelector('#eventSourceSelect input[data-all]');
      if (all) all.checked = true;
      root.querySelectorAll('#eventSourceSelect input[name="source"]:not([data-all])').forEach(cb => (cb.checked = true));
      root.querySelectorAll('.keywordList li.selected').forEach(li => li.classList.remove('selected'));
      root.querySelectorAll('#event-search,#relationship-search,#place-search,#occupation-search').forEach(i => (i.value = ''));
      const allSources = root.querySelector('#sourceSelect input[data-all]');
      if (allSources) allSources.checked = true;
      root.querySelectorAll('#sourceSelect input[name="source"]:not([data-all])').forEach(cb => (cb.checked = true));
      writeFilterParamsToUrl(s);
      runSearch();
    });
  },

  // async fetch(state) {
  //   // Return current results (orchestrator will call render with these)
  //   console.log("Fetching event factoids with filters:", state.filters.event);
  //   return await fetchEventFactoids(state.filters.event);
  // },

    fetch: async (state) => {
      const s = state.filters.event ?? {};
      console.log("State filters for events:", s);
      const hasName = !!(s.name && s.name.trim());
      const hasGender = (s.selectedGenderKeywords?.size ?? 0) > 0;
      const hasOccupation = (s.selectedOccupationKeywords?.size ?? 0) > 0;
      console.log('Filter checks - hasName:', hasName, 'hasGender:', hasGender, 'hasOccupation:', hasOccupation);
      // Check if any other facet filters are applied
      const hasAnyOtherFacet =
        ((s.selectedSourceKeywords?.size ?? 3) > 0 && (s.selectedSourceKeywords?.size ?? 3) < 3) ||
        (s.selectedEventKeywords?.size ?? 0) > 0 ||
        s.uncertainty ||
        (s.selectedPlaceKeywords?.size ?? 0) > 0;

      if (hasName || hasGender || hasOccupation) {
      // Need to process JSON results into rows  
      const bindings = persons.results?.bindings ?? [];
      let rows = bindings.map(b => ({
      person: str(b.person),
      label_en: str(b.label_en),
      label_syr: str(b.label_syr),
      description: str(b.description),
      gender: str(b.gender),
      occupation: str(b.occupation), uri: str(b.factoid), eventKeyword: str(b.eventKeyword), source: str(b.source)  
    }));
    // ---------- SIMPLE (JSON) ----------
  // if (!hasName && !hasAnyOtherFacet) {
  //   s.personURIs = rows.map(r => r.person);
  //   console.log('Default: showing all people from JSON (' + rows.length + ' rows)');
  //   return rows;
  // }
   if (hasName) { 
        const q = (s.name ?? '').trim().toLowerCase();
        console.log('Filtering by name search:', q);
        if (q) {
        rows = rows.filter(r =>
            (r.label_en && r.label_en.toLowerCase().includes(q)) ||
            (r.label_syr && r.label_syr.toLowerCase().includes(q))
        );
        }
   }
     // ---------- FILTER BY GENDER ----------
  if (hasGender) {
    const selectedGenders = Array.from(s.selectedGenderKeywords).map(g => g.toLowerCase());
    console.log('Filtering by genders:', selectedGenders);
    rows = rows.filter(r =>
    r.gender && selectedGenders.some(sel => sel === r.gender)
    );
  }

  // ---------- FILTER BY OCCUPATION ----------
  if (hasOccupation) {
    const selectedOccs = Array.from(s.selectedOccupationKeywords);
    console.log('Filtering by occupations:', selectedOccs);
    console.log('Sample occupation values from data:', rows.slice(0, 5).map(r => r.occupation));
    rows = rows.filter(r => {
      if (!r.occupation) return false;
      // Check if any selected occupation URI matches the occupation string
      // The JSON contains simple strings like "clergy", "priests", "monks"
      // The selected URIs are like "http://syriaca.org/taxonomy/clergy"
      return selectedOccs.some(sel => {
        // Extract the last part of the URI (after the last slash) and compare
        const occupationFromUri = sel.split('/').pop();
        const match = r.occupation === occupationFromUri || r.occupation === sel;
        if (match) {
          console.log(`Occupation match: ${r.occupation} matches ${sel} (extracted: ${occupationFromUri})`);
        }
        return match;
      });
    });
    console.log('Rows after occupation filter:', rows.length);
  }
        const personURIs = rows.map(r => r.person);
        const eventURIs = [...new Set(rows.map(r => r.uri))];
        // Bind directly to state for later SPARQL queries
        state.filters.event.persons = [...new Set(personURIs)];

        state.filters.event.events = [...new Set(eventURIs)];
        console.log('Bound personURIs to state:', personURIs.length);
        console.log('Event URIs:', eventURIs);
        console.log('fetch -> JSON rows:', rows.length, 'sample:', rows[0]);
    // If we pull factoid description from JSON, we can return here, but for now we re-query SPARQL for full factoid data
    }

    // ---------- COMPLEX (LIVE) ----------

    return await fetchEventFactoids(state.filters.event);

    },

  render(facts) {
    // Render into the event results panel
    const panel = document.getElementById('event--items');
    if (!panel) return;

    if (!facts || facts.length === 0) {
      panel.innerHTML = `<div class="text-muted">No event factoids match these filters.</div>`;
      return;
    }

    panel.innerHTML = `
      <h4>Event Factoids</h4>
      <h5 class="mt-2 mb-3">${facts.length} results</h5>
      <ul class="result-list">
        ${facts.map(f => `
      <li style="padding: 1rem 0; border-bottom: 1px solid #ccc;">
        ${cleanPunctuationSpacing(f.description) ? `<em> ${cleanPunctuationSpacing(f.description)} </em>` : ''}${f.source ? ` [${getSourceLabel(f.source)}]<br/>` : ''}
        ${f.eventKeyword ? `${f.eventKeyword}<br/> ` : ''}
        <a href="${f.uri}" >${f.uri}</a> 
      </li>
        `).join('')}
      </ul>
    `;
  }
};
const sourceLabels = {
  "https://spear-prosop.org/letters-severus": "Letters of Severus of Antioch",
  "https://spear-prosop.org/lives-eastern-saints": "Lives of the Eastern Saints",
  "https://spear-prosop.org/chronicle-edessa": "Chronicle of Edessa"

};

function getSourceLabel(uri) {
  return sourceLabels[uri] || prettifyUri(uri);
}

