// /modes/event.js
import {
  getEventKeywords,
  getRelationshipOptions,
  getPlaceOptions,
  getOccupationOptions,
  renderKeywordList
} from '../menu.js';

import { renderKeywordPrettyList } from '../list.js';

// Use your existing fetcher that already works for event factoids
// (adjust the path if your fetcher lives elsewhere)
import { fetchEventFactoids } from '../search.js';

function writeFilterParamsToUrl(filterState) {
  // Preserve existing params like ?type=event, only replace filter params
  const url = new URL(location.href);
  const keys = ['gender','uncertainty','source','occupation','event','place'];
  keys.forEach(k => url.searchParams.delete(k));

  for (const uri of filterState.selectedGenderKeywords)      url.searchParams.append('gender', uri);
  if (filterState.uncertainty)                                url.searchParams.set('uncertainty', filterState.uncertainty);
  for (const uri of filterState.selectedSourceKeywords)       url.searchParams.append('source', uri);
  for (const uri of filterState.selectedOccupationKeywords)   url.searchParams.append('occupation', uri);
  for (const uri of filterState.selectedEventKeywords)        url.searchParams.append('event', uri);
  for (const uri of filterState.selectedPlaceKeywords)        url.searchParams.append('place', uri);
  history.replaceState({}, '', url);
}

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
                Source
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
                  Events
                  <div class="d-flex gap-2">
                    <button class="clear-section-btn" data-section="gender" title="Clear gender filter">
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

        <div class="filter-section">
                <div class="filter-title d-flex justify-content-between align-items-center">
                  Place
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
      selectedEventKeywords:        new Set(),
      selectedRelationshipKeywords: new Set(),
      selectedGenderKeywords:       new Set(),
      selectedUncertaintyKeywords:  new Set(), // not used directly; we store string in .uncertainty
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

    // Clear all
    root.querySelector('#clearFiltersBtn')?.addEventListener('click', () => {
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

      writeFilterParamsToUrl(s);
      runSearch();
    });
  },

  async fetch(state) {
    // Return current results (orchestrator will call render with these)
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
        ${f.description ? `<em> ${f.description} </em>` : ''}${f.source ? ` [${getSourceLabel(f.source)}]<br/>` : ''}
        ${f.eventKeyword ? `${f.eventKeyword}<br/> ` : ''}
        <a href="${f.uri}" target="_blank">${f.uri}</a> 

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

