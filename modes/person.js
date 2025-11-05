import {
  getEventKeywords,
  getRelationshipOptions,
  getPlaceOptions,
  getOccupationOptions,
  renderKeywordList
} from '../menu.js';

import { renderKeywordPrettyList } from '../list.js';
import persons from "../person/person.json" with { type: 'json' };

// import { fetchPersonFactoids } from '../search.js';
import { fetchData } from '../person/search.js';

function writeFilterParamsToUrl(filterState) {
  const url = new URL(location.href);
  // include nameSearch
  const keys = ['nameSearch','gender','source','occupation','event','relationship','place'];
  keys.forEach(k => url.searchParams.delete(k));

  if (filterState.name && filterState.name.trim()) {
    url.searchParams.set('nameSearch', filterState.name.trim());
  }
  for (const uri of filterState.selectedGenderKeywords)      url.searchParams.append('gender', uri);
  if(filterState.selectedSourceKeywords.size < 3){
  for (const uri of filterState.selectedSourceKeywords)       url.searchParams.append('source', uri);}
  for (const uri of filterState.selectedOccupationKeywords)   url.searchParams.append('occupation', uri);
  for (const uri of filterState.selectedEventKeywords)        url.searchParams.append('event', uri);
  for (const uri of filterState.selectedPlaceKeywords)        url.searchParams.append('place', uri);

  history.replaceState({}, '', url);
}

// put this near your fetch()
const str = (x) => {
  if (x == null) return '';
  if (typeof x === 'object' && 'value' in x) return (x.value ?? '').toString();
  return ('' + x);
};

export default {
  id: 'person',

  sidebar(state) {
    return `
      <div class="filter-sidebar" id="filter-sidebar">
        <div className="filter-section"><div class="filter-title d-flex justify-content-between align-items-right" style="justify-items: right;">                        
            <button type="button" class="btn btn-outline-dark" data-type="person" id="clearFiltersBtn">
              Remove Filters/Show All Persons
            </button></div></div>
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
                  Genders
                  <div class="d-flex gap-2">
                    <button class="clear-section-btn" data-section="gender" title="Clear gender filter">
                      <span>×</span>
                    </button>
                    <button class="collapse-toggle" data-target="gender-filter">
                      <span>−</span>
                    </button>
                  </div>
                </div>
       
                              <div class="filter-section">
   
      </div>
              </div> -->
            <div class="filter-section">
              <div class="filter-title d-flex justify-content-between align-items-center">
                Genders
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
                 <!-- Occupations Filter -->
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
        </div>
        </div>
    </div>
              <!-- Events Filter -->
              <div class="filter-section">
                     <div class="filter-title d-flex justify-content-between align-items-center">
                  Associated Events
                  <div class="d-flex gap-2">
                    <button class="clear-section-btn" data-section="events" title="Clear events filter">
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

 <!-- Relationships Filter -->
      <div class="filter-section">
                     <div class="filter-title d-flex justify-content-between align-items-center">
                  Associated Relationships
                  <div class="d-flex gap-2">
                    <button class="clear-section-btn" data-section="relationships" title="Clear relationships filter">
                      <span>×</span>
                    </button>
                    <button class="collapse-toggle" data-target="relationships-filter">
                      <span>−</span>
                    </button>
                  </div>
                </div>
                        <div class="filter-content" id="relationships-filter">
                  <div class="filter-control">
                    <label for="relationship-multiselect">Select relationships:</label>
                    <div class="multiselect-container">
                      <input type="text" id="relationship-search" class="form-control form-control-sm"
                        placeholder="Type to search relationships..." autocomplete="off" />
                      <div class="multiselect-dropdown" id="relationship-dropdown">
     
                      </div>
                      <div class="selected-items" id="relationship-selected">
                        <!-- Selected items will appear here -->
                      </div>
                    </div>
                  </div>
                
        <div id="relationshipKeywordList" class="keywordList">
          <ul id="relationshipKeywordItems" class="keywordItems"></ul>
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
            </div>
        </div>
    </div>

    `;
  },
  

  bind(root, state, runSearch) {
    // one event-specific bucket in shared state
    state.filters.person ??= {
        name: '',   
      selectedEventKeywords:        new Set(),
      selectedRelationshipKeywords: new Set(),
      selectedGenderKeywords:       new Set(),
      selectedPlaceKeywords:        new Set(),
      selectedOccupationKeywords:   new Set(),
      selectedSourceKeywords:       new Set([
        'https://spear-prosop.org/letters-severus',
        'https://spear-prosop.org/lives-eastern-saints',
        'https://spear-prosop.org/chronicle-edessa'
      ]),
    };

    const s = state.filters.person;
    const params = new URLSearchParams(location.search);
    const initialName = params.get('nameSearch') || '';
    if (initialName) s.name = initialName;
    const nameInput = root.querySelector('#name-search');
    if (nameInput) {
        if (initialName) nameInput.value = initialName;
        // Debounce is optional; direct is fine for local JSON
        nameInput.addEventListener('input', (e) => {
        s.name = e.target.value.trim();
        writeFilterParamsToUrl(s);
        runSearch();
        });
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

    renderKeywordPrettyList(getEventKeywords(), 'eventKeywordItems','eventKeywordList' ,'keyword', 'keyword', (uri) => {
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
      const p = state.filters.person;
      if (!p) return;

      console.log('Clearing section:', section);
      if (section=== 'names') {
        p.name = '';
        p.personURIs = [];
        p.persons = [];
      }
      const map = {
        names:        'name',
        gender:       'selectedGenderKeywords',
        source:       'selectedSourceKeywords',
        occupations:  'selectedOccupationKeywords',
        events:       'selectedEventKeywords',
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

      writeFilterParamsToUrl(p);
      runSearch();
    });

// root.addEventListener('clearAll', () => {
//   const p = state.filters.person;
//   if (!p) return;
//   p.name = '';
//   p.personURIs = [];
//   p.persons = [];
//   p.selectedEventKeywords.clear();
//   p.selectedRelationshipKeywords.clear();
//   p.selectedPlaceKeywords.clear();
//   p.selectedOccupationKeywords.clear();
//   p.selectedGenderKeywords.clear();
//   p.selectedSourceKeywords = new Set([
//     'https://spear-prosop.org/letters-severus',
//     'https://spear-prosop.org/lives-eastern-saints',
//     'https://spear-prosop.org/chronicle-edessa'
//   ]);

//   root.querySelectorAll('input[type="checkbox"], input[type="radio"]').forEach(cb => (cb.checked = false));
//   root.querySelectorAll('input[type="text"], select').forEach(el => (el.value = ''));

//   writeFilterParamsToUrl(p);
//   runSearch();
// });

    // Clear all
    root.querySelector('#clearFiltersBtn')?.addEventListener('click', () => {

        console.log('Clearing all person filters');

      s.name = '';  
      s.personURIs = [];
      s.persons = [];
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

      // reset inputs visually
      root.querySelectorAll('input[name="gender"]').forEach(cb => (cb.checked = false));
      const all = root.querySelector('#sourceSelect input[data-all]');
      if (all) all.checked = true;
      root.querySelectorAll('#sourceSelect input[name="source"]:not([data-all])').forEach(cb => (cb.checked = true));
      root.querySelectorAll('.keywordList li.selected').forEach(li => li.classList.remove('selected'));
      root.querySelectorAll('#event-search,#relationship-search,#place-search,#occupation-search,#name-search',).forEach(i => (i.value = ''));

      writeFilterParamsToUrl(s);
      runSearch();
    });
  },


    fetch: async (state) => {
      const s = state.filters.person ?? {};
      console.log(s);
      console.log(s.selectedSourceKeywords.size);
      const hasName = !!(s.name && s.name.trim());
      const hasAnyFacet =
        ((s.selectedSourceKeywords?.size ?? 3) > 0 && (s.selectedSourceKeywords?.size ?? 3) < 3) ||
        (s.selectedGenderKeywords?.size ?? 0) > 0 ||
        (s.selectedEventKeywords?.size ?? 0) > 0 ||
        (s.selectedRelationshipKeywords?.size ?? 0) > 0 ||
        (s.selectedPlaceKeywords?.size ?? 0) > 0 ||
        (s.selectedOccupationKeywords?.size ?? 0) > 0;

    // ---------- SIMPLE (JSON) ----------
      // ✅ Case 0: no filters, no name → show all people from JSON
  if (!hasName && !hasAnyFacet) {
    const bindings = persons.results?.bindings ?? [];
    const rows = bindings.map(b => ({
      person: str(b.person),
      label_en: str(b.label_en),
      label_syr: str(b.label_syr),
      description: str(b.description),
    }));

    s.personURIs = rows.map(r => r.person);
    console.log('Default: showing all people from JSON (' + rows.length + ' rows)');
    return rows;
  }
   if (state.filters.person?.name) { 
        const bindings = persons.results?.bindings ?? [];
        let rows = bindings.map(b => ({
        person:      str(b.person),
        label_en:    str(b.label_en),
        label_syr:   str(b.label_syr),
        description: str(b.description)
        }));

        const q = (s.name ?? '').trim().toLowerCase();
        if (q) {
        rows = rows.filter(r =>
            (r.label_en && r.label_en.toLowerCase().includes(q)) ||
            (r.label_syr && r.label_syr.toLowerCase().includes(q))
        );
        }
        const personURIs = rows.map(r => r.person);

        // Bind directly to state for later SPARQL queries
        state.filters.person.persons = personURIs;

        console.log('Bound personURIs to state:', personURIs.length);
        console.log('fetch -> JSON rows:', rows.length, 'sample:', rows[0]);
  
      if (!hasAnyFacet) {
        console.log('No facets selected, returning JSON-filtered rows.');
        return rows;
      }
    }


    // ---------- COMPLEX (LIVE) ----------

    return await fetchData(state.filters.person);

    },

  render(facts) {
    const panel = document.getElementById('person--items');
    if (!panel) return;
    if (!facts || facts.length === 0) {
      panel.innerHTML = `<div class="text-muted">No person in the database match these filters.</div>`;
      return;
    }
    panel.innerHTML = `
      <h4>People</h4>
      <h5 class="mt-2 mb-3">${facts.length} results</h5>
      <ul class="result-list">
        ${facts.map(f => `
          <li style="padding: 1rem 0; border-bottom: 1px solid #ccc;">
            <a href="${f.person}" target="_blank">${f.label_en ? ` ${f.label_en} -- ` : ''}${f.label_syr ? ` ${f.label_syr}` : ''}
            </a>
            <br/>
            ${f.person ? ` [${f.person}]<br/>` : ''}
            ${f.description ? `<em> ${f.description} </em>` : ''}
          </li>
        `).join('')}
      </ul>
    `;
  }
};


