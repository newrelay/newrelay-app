(function() {
  const currentScript = document.currentScript;
  if (!currentScript) return;

  const token = currentScript.getAttribute('data-token');
  if (!token) return;

  // Infer base URL from the script source
  const scriptUrl = new URL(currentScript.src);
  const baseUrl = scriptUrl.origin;
  
  const containerId = 'nr-widget-' + Math.random().toString(36).substr(2, 9);
  
  // Create wrapper container
  const container = document.createElement('div');
  container.id = containerId;
  container.className = 'nr-reputation-widget';
  container.style.fontFamily = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif';
  container.style.maxWidth = '100%';
  container.style.margin = '20px 0';
  // Inject widget safely (handle case where script is placed in <head> or raw html file)
  function injectContainer() {
    if (currentScript.parentNode.tagName === 'HEAD') {
      if (document.body) {
        document.body.appendChild(container);
      } else {
        document.addEventListener('DOMContentLoaded', () => document.body.appendChild(container));
      }
    } else {
      currentScript.parentNode.insertBefore(container, currentScript.nextSibling);
    }
  }
  injectContainer();

  // Helper to render stars
  function renderStars(rating) {
    let html = '<div style="display: flex; color: #fbbf24; gap: 2px;">';
    for (let i = 1; i <= 5; i++) {
      html += `<span style="font-size: 14px;">${i <= rating ? '★' : '☆'}</span>`;
    }
    html += '</div>';
    return html;
  }

  // Fetch reviews
  fetch(`${baseUrl}/reputation/widget/${token}/reviews`)
    .then(res => res.json())
    .then(data => {
      const widget = data.widget;
      const reviews = data.reviews;
      
      if (!reviews || reviews.length === 0) {
        container.innerHTML = `
          <div style="background: #f8fafc; border: 1px dashed #cbd5e1; border-radius: 12px; padding: 24px; text-align: center;">
            <p style="font-size: 14px; color: #64748b; margin: 0; font-weight: 500;">Widget configured successfully!</p>
            <p style="font-size: 12px; color: #94a3b8; margin: 4px 0 0 0;">Awaiting your first reviews to display here.</p>
          </div>
        `;
        return;
      }

      let html = '';

      if (widget.style === 'grid') {
        html += `<div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 16px;">`;
        reviews.slice(0, 4).forEach(r => {
          html += `
            <div style="background: #fff; border: 1px solid #e2e8f0; border-radius: 12px; padding: 16px; box-shadow: 0 1px 2px rgba(0,0,0,0.05); display: flex; flex-direction: column; gap: 8px;">
              <div style="display: flex; justify-content: space-between; align-items: center;">
                ${renderStars(r.rating)}
                <span style="font-size: 11px; color: #94a3b8;">${new Date(r.reviewed_at).toLocaleDateString()}</span>
              </div>
              <p style="font-size: 13px; color: #475569; font-style: italic; line-height: 1.5; margin: 0; display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden;">"${r.body}"</p>
              <div style="display: flex; align-items: center; gap: 8px; margin-top: auto;">
                <span style="font-size: 13px; font-weight: 700; color: #1e293b; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">${r.reviewer_name}</span>
                <span style="font-size: 10px; font-weight: 700; color: #94a3b8; text-transform: uppercase;">${r.provider}</span>
              </div>
            </div>
          `;
        });
        html += `</div>`;
      } else {
        // Carousel style (Simplified)
        html += `<div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 16px; padding: 24px; position: relative;">`;
        
        const review = reviews[0]; // Show latest for now
        html += `
          <div style="display: flex; flex-direction: column; gap: 12px;">
            <div style="display: flex; justify-content: space-between; align-items: center;">
              ${renderStars(review.rating)}
              <span style="font-size: 11px; color: #94a3b8;">${new Date(review.reviewed_at).toLocaleDateString()}</span>
            </div>
            <p style="font-size: 14px; color: #334155; font-style: italic; line-height: 1.6; margin: 0;">"${review.body}"</p>
            <div style="display: flex; align-items: center; gap: 8px;">
              <span style="font-size: 14px; font-weight: 700; color: #0f172a;">${review.reviewer_name}</span>
              <span style="width: 4px; height: 4px; background: #cbd5e1; border-radius: 50%;"></span>
              <span style="font-size: 10px; font-weight: 700; padding: 2px 8px; background: #f1f5f9; color: #64748b; border-radius: 999px; text-transform: uppercase;">${review.provider}</span>
            </div>
          </div>
        `;
        html += `</div>`;
      }

      if (!widget.hide_watermark) {
        html += `
          <div style="text-align: center; padding-top: 12px; font-size: 11px; color: #94a3b8;">
            Powered by <span style="font-weight: 700; color: #475569;">newrelay</span>
          </div>
        `;
      }

      container.innerHTML = html;
    })
    .catch(err => console.error('Failed to load reputation widget', err));
})();
