// Animated Counter
function animateCounter() {
    const countElement = document.getElementById('count');
    const target = 1248;
    const duration = 2000; // 2 seconds
    const startTime = performance.now();

    function update(currentTime) {
        const elapsed = currentTime - startTime;
        const progress = Math.min(elapsed / duration, 1);
        
        // Easing function: easeOutExpo
        const easeProgress = progress === 1 ? 1 : 1 - Math.pow(2, -10 * progress);
        
        const currentCount = Math.floor(easeProgress * target);
        countElement.textContent = currentCount.toLocaleString();

        if (progress < 1) {
            requestAnimationFrame(update);
        }
    }

    requestAnimationFrame(update);
}

// Intersection Observer for animations
const observerOptions = {
    threshold: 0.2
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            if (entry.target.id === 'count') {
                animateCounter();
                observer.unobserve(entry.target);
            }
        }
    });
}, observerOptions);

document.addEventListener('DOMContentLoaded', () => {
    const countElement = document.getElementById('count');
    if (countElement) {
        observer.observe(countElement);
    }

    // Scroll reveal logic
    const sections = document.querySelectorAll('section');
    const revealObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    }, { threshold: 0.1 });

    sections.forEach(section => {
        section.style.opacity = '0';
        section.style.transform = 'translateY(30px)';
        section.style.transition = 'all 1s cubic-bezier(0.16, 1, 0.3, 1)';
        revealObserver.observe(section);
    });
});
