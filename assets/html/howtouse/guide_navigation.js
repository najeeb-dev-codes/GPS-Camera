(() => {
  const notifyFlutter = () => {
    const page = document.body.dataset.guidePage === 'detail' ? 'detail' : 'list';
    if (window.GuideNavigation) window.GuideNavigation.postMessage(page);
  };

  const hideMissingImages = () => {
    document.querySelectorAll('.guide-image img').forEach((image) => {
      const hideFrame = () => {
        const frame = image.closest('.guide-image');
        if (frame) frame.classList.add('is-missing');
      };
      image.addEventListener('error', hideFrame, { once: true });
      if (image.complete && image.naturalWidth === 0) hideFrame();
    });
  };

  document.addEventListener('DOMContentLoaded', () => {
    hideMissingImages();
    notifyFlutter();
  });

  window.addEventListener('pageshow', notifyFlutter);
})();
