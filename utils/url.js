// /utils/urlState.js
export const url = {
  get() {
    const sp = new URLSearchParams(location.search);
    const obj = {};
    // collect repeated keys as arrays
    for (const [k, v] of sp.entries()) {
      if (obj[k] === undefined) obj[k] = v;
      else obj[k] = Array.isArray(obj[k]) ? [...obj[k], v] : [obj[k], v];
    }
    return obj;
  },
  getAll(key) {
    return new URLSearchParams(location.search).getAll(key);
  },
  patch(patchObj, { replace = true } = {}) {
    const sp = new URLSearchParams(location.search);
    for (const [k, v] of Object.entries(patchObj)) {
      if (v === null || v === undefined || v === '' || (Array.isArray(v) && v.length === 0)) {
        sp.delete(k);
      } else if (Array.isArray(v)) {
        sp.delete(k);
        v.forEach(val => sp.append(k, val));
      } else {
        sp.set(k, v);
      }
    }
    history[replace ? 'replaceState' : 'pushState']({}, '', `?${sp}`);
    // notify listeners (modes) that params changed
    window.dispatchEvent(new Event('popstate'));
  },
  clear(keys) {
    const sp = new URLSearchParams(location.search);
    keys.forEach(k => sp.delete(k));
    history.replaceState({}, '', `?${sp}`);
    window.dispatchEvent(new Event('popstate'));
  }
};
