const form = document.querySelector('#link-form');
const urlInput = document.querySelector('#url-input');
const codeInput = document.querySelector('#code-input');
const message = document.querySelector('#message');
const linksBody = document.querySelector('#links-body');
const refreshButton = document.querySelector('#refresh-button');

function setMessage(text, type = 'info') {
  message.textContent = text;
  message.dataset.type = type;
}

function shortUrl(code) {
  return `${window.location.origin}/r/${code}`;
}

function renderLinks(links) {
  linksBody.replaceChildren();

  if (!links.length) {
    const row = document.createElement('tr');
    const cell = document.createElement('td');
    cell.colSpan = 3;
    cell.className = 'empty';
    cell.textContent = 'No links yet.';
    row.append(cell);
    linksBody.append(row);
    return;
  }

  for (const link of links) {
    const url = shortUrl(link.code);
    const row = document.createElement('tr');
    const shortCell = document.createElement('td');
    const urlCell = document.createElement('td');
    const clicksCell = document.createElement('td');
    const anchor = document.createElement('a');

    anchor.href = url;
    anchor.target = '_blank';
    anchor.rel = 'noreferrer';
    anchor.textContent = url;
    shortCell.append(anchor);
    urlCell.className = 'destination';
    urlCell.textContent = link.original_url;
    clicksCell.textContent = String(link.clicks);
    row.append(shortCell, urlCell, clicksCell);
    linksBody.append(row);
  }
}

async function loadLinks() {
  try {
    const response = await fetch('/api/links');
    const data = await response.json();
    if (!response.ok) {
      throw new Error(data.error || 'Unable to load links.');
    }
    renderLinks(data.links || []);
  } catch (err) {
    linksBody.replaceChildren();
    const row = document.createElement('tr');
    const cell = document.createElement('td');
    cell.colSpan = 3;
    cell.className = 'empty';
    cell.textContent = err.message;
    row.append(cell);
    linksBody.append(row);
  }
}

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  setMessage('Creating link...');

  const payload = {
    url: urlInput.value,
    custom_code: codeInput.value || undefined,
  };

  try {
    const response = await fetch('/api/links', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.error || 'Unable to create link.');
    }

    setMessage(`Created: ${shortUrl(data.link.code)}`, 'success');
    form.reset();
    await loadLinks();
  } catch (err) {
    setMessage(err.message, 'error');
  }
});

refreshButton.addEventListener('click', loadLinks);
loadLinks();
