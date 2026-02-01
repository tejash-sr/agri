/**
 * AgriSense Pro - Main JavaScript
 * AI Crop Intelligence & Farmer Profit Engine
 */

// ============================================================================
// Initialize AOS (Animate on Scroll)
// ============================================================================
document.addEventListener('DOMContentLoaded', function() {
    AOS.init({
        duration: 800,
        easing: 'ease-out-cubic',
        once: true,
        offset: 50
    });
});

// ============================================================================
// Navbar Scroll Effect
// ============================================================================
const navbar = document.getElementById('navbar');
let lastScrollY = window.scrollY;

window.addEventListener('scroll', () => {
    if (window.scrollY > 50) {
        navbar.classList.add('scrolled');
    } else {
        navbar.classList.remove('scrolled');
    }
    lastScrollY = window.scrollY;
});

// ============================================================================
// Mobile Menu Toggle
// ============================================================================
const mobileMenuBtn = document.getElementById('mobileMenuBtn');
const navLinks = document.getElementById('navLinks');

if (mobileMenuBtn) {
    mobileMenuBtn.addEventListener('click', () => {
        navLinks.classList.toggle('active');
        mobileMenuBtn.classList.toggle('active');
    });
}

// ============================================================================
// Smooth Scroll for Navigation Links
// ============================================================================
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function(e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        
        if (target) {
            // Close mobile menu if open
            navLinks.classList.remove('active');
            mobileMenuBtn.classList.remove('active');
            
            // Scroll to target
            const offsetTop = target.offsetTop - 80;
            window.scrollTo({
                top: offsetTop,
                behavior: 'smooth'
            });
            
            // Update active link
            document.querySelectorAll('.nav-links a').forEach(link => {
                link.classList.remove('active');
            });
            this.classList.add('active');
        }
    });
});

// ============================================================================
// Active Link on Scroll
// ============================================================================
const sections = document.querySelectorAll('section[id]');

window.addEventListener('scroll', () => {
    const scrollY = window.pageYOffset;
    
    sections.forEach(section => {
        const sectionHeight = section.offsetHeight;
        const sectionTop = section.offsetTop - 100;
        const sectionId = section.getAttribute('id');
        const navLink = document.querySelector(`.nav-links a[href="#${sectionId}"]`);
        
        if (navLink && scrollY > sectionTop && scrollY <= sectionTop + sectionHeight) {
            document.querySelectorAll('.nav-links a').forEach(link => {
                link.classList.remove('active');
            });
            navLink.classList.add('active');
        }
    });
});

// ============================================================================
// Pricing Toggle (Monthly/Yearly)
// ============================================================================
const pricingToggle = document.getElementById('pricingToggle');

if (pricingToggle) {
    pricingToggle.addEventListener('change', function() {
        const monthlyPrices = document.querySelectorAll('.monthly-price');
        const yearlyPrices = document.querySelectorAll('.yearly-price');
        const toggleLabels = document.querySelectorAll('.pricing-toggle span');
        
        if (this.checked) {
            // Show yearly prices
            monthlyPrices.forEach(el => el.style.display = 'none');
            yearlyPrices.forEach(el => el.style.display = 'inline');
            toggleLabels[0].classList.remove('active');
            toggleLabels[1].classList.add('active');
        } else {
            // Show monthly prices
            monthlyPrices.forEach(el => el.style.display = 'inline');
            yearlyPrices.forEach(el => el.style.display = 'none');
            toggleLabels[0].classList.add('active');
            toggleLabels[1].classList.remove('active');
        }
    });
}

// ============================================================================
// Animated Counter
// ============================================================================
const animateCounter = (element, target, duration = 2000) => {
    let start = 0;
    const increment = target / (duration / 16);
    
    const updateCounter = () => {
        start += increment;
        if (start < target) {
            element.textContent = Math.floor(start).toLocaleString();
            requestAnimationFrame(updateCounter);
        } else {
            element.textContent = target.toLocaleString();
        }
    };
    
    updateCounter();
};

// Intersection Observer for counters
const counterObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            const element = entry.target;
            const target = parseInt(element.getAttribute('data-target'));
            
            if (!element.classList.contains('counted')) {
                element.classList.add('counted');
                animateCounter(element, target);
            }
        }
    });
}, { threshold: 0.5 });

document.querySelectorAll('.stat-value[data-target]').forEach(counter => {
    counterObserver.observe(counter);
});

// ============================================================================
// Contact Form Handling
// ============================================================================
const contactForm = document.getElementById('contactForm');

if (contactForm) {
    contactForm.addEventListener('submit', async function(e) {
        e.preventDefault();
        
        const submitBtn = this.querySelector('button[type="submit"]');
        const originalText = submitBtn.innerHTML;
        
        // Show loading state
        submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Sending...';
        submitBtn.disabled = true;
        
        // Collect form data
        const formData = new FormData(this);
        const data = Object.fromEntries(formData.entries());
        
        // Simulate API call (replace with actual endpoint)
        try {
            await new Promise(resolve => setTimeout(resolve, 1500));
            
            // Show success message
            showNotification('Message sent successfully! We\'ll get back to you soon.', 'success');
            this.reset();
        } catch (error) {
            showNotification('Failed to send message. Please try again.', 'error');
        } finally {
            submitBtn.innerHTML = originalText;
            submitBtn.disabled = false;
        }
    });
}

// ============================================================================
// Notification System
// ============================================================================
function showNotification(message, type = 'info') {
    // Remove existing notifications
    const existing = document.querySelector('.notification');
    if (existing) existing.remove();
    
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.innerHTML = `
        <div class="notification-content">
            <i class="fas fa-${type === 'success' ? 'check-circle' : type === 'error' ? 'exclamation-circle' : 'info-circle'}"></i>
            <span>${message}</span>
        </div>
        <button class="notification-close">&times;</button>
    `;
    
    // Add styles
    notification.style.cssText = `
        position: fixed;
        top: 100px;
        right: 20px;
        padding: 16px 24px;
        background: ${type === 'success' ? '#4CAF50' : type === 'error' ? '#F44336' : '#2196F3'};
        color: white;
        border-radius: 12px;
        box-shadow: 0 4px 20px rgba(0,0,0,0.2);
        display: flex;
        align-items: center;
        gap: 12px;
        z-index: 9999;
        animation: slideIn 0.3s ease;
    `;
    
    // Add animation keyframes
    if (!document.querySelector('#notification-styles')) {
        const style = document.createElement('style');
        style.id = 'notification-styles';
        style.textContent = `
            @keyframes slideIn {
                from { transform: translateX(100%); opacity: 0; }
                to { transform: translateX(0); opacity: 1; }
            }
            @keyframes slideOut {
                from { transform: translateX(0); opacity: 1; }
                to { transform: translateX(100%); opacity: 0; }
            }
            .notification-content {
                display: flex;
                align-items: center;
                gap: 10px;
            }
            .notification-close {
                background: none;
                border: none;
                color: white;
                font-size: 20px;
                cursor: pointer;
                opacity: 0.8;
                margin-left: 10px;
            }
            .notification-close:hover {
                opacity: 1;
            }
        `;
        document.head.appendChild(style);
    }
    
    document.body.appendChild(notification);
    
    // Close button handler
    notification.querySelector('.notification-close').addEventListener('click', () => {
        notification.style.animation = 'slideOut 0.3s ease forwards';
        setTimeout(() => notification.remove(), 300);
    });
    
    // Auto remove after 5 seconds
    setTimeout(() => {
        if (notification.parentNode) {
            notification.style.animation = 'slideOut 0.3s ease forwards';
            setTimeout(() => notification.remove(), 300);
        }
    }, 5000);
}

// ============================================================================
// Testimonials Slider (Optional - for future enhancement)
// ============================================================================
class TestimonialSlider {
    constructor(container) {
        this.container = container;
        this.cards = container.querySelectorAll('.testimonial-card');
        this.currentIndex = 0;
        this.autoPlayInterval = null;
        
        if (this.cards.length > 1) {
            this.init();
        }
    }
    
    init() {
        // Add navigation dots
        this.createDots();
        
        // Start autoplay
        this.startAutoPlay();
        
        // Pause on hover
        this.container.addEventListener('mouseenter', () => this.stopAutoPlay());
        this.container.addEventListener('mouseleave', () => this.startAutoPlay());
    }
    
    createDots() {
        const dotsContainer = document.createElement('div');
        dotsContainer.className = 'slider-dots';
        dotsContainer.style.cssText = `
            display: flex;
            justify-content: center;
            gap: 10px;
            margin-top: 30px;
        `;
        
        this.cards.forEach((_, index) => {
            const dot = document.createElement('button');
            dot.className = `slider-dot ${index === 0 ? 'active' : ''}`;
            dot.style.cssText = `
                width: 10px;
                height: 10px;
                border-radius: 50%;
                border: none;
                background: ${index === 0 ? '#2E7D32' : '#BDBDBD'};
                cursor: pointer;
                transition: 0.3s ease;
            `;
            dot.addEventListener('click', () => this.goTo(index));
            dotsContainer.appendChild(dot);
        });
        
        this.container.appendChild(dotsContainer);
        this.dots = dotsContainer.querySelectorAll('.slider-dot');
    }
    
    goTo(index) {
        this.currentIndex = index;
        // Animation logic here for single-card view
        this.updateDots();
    }
    
    updateDots() {
        this.dots.forEach((dot, index) => {
            dot.style.background = index === this.currentIndex ? '#2E7D32' : '#BDBDBD';
        });
    }
    
    startAutoPlay() {
        this.autoPlayInterval = setInterval(() => {
            this.currentIndex = (this.currentIndex + 1) % this.cards.length;
            this.updateDots();
        }, 5000);
    }
    
    stopAutoPlay() {
        clearInterval(this.autoPlayInterval);
    }
}

// ============================================================================
// Lazy Loading Images
// ============================================================================
const lazyImages = document.querySelectorAll('img[data-src]');

const imageObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            const img = entry.target;
            img.src = img.dataset.src;
            img.removeAttribute('data-src');
            imageObserver.unobserve(img);
        }
    });
});

lazyImages.forEach(img => imageObserver.observe(img));

// ============================================================================
// Parallax Effect for Hero Section
// ============================================================================
const heroVisual = document.querySelector('.hero-visual');

if (heroVisual) {
    window.addEventListener('scroll', () => {
        const scrolled = window.pageYOffset;
        const rate = scrolled * 0.3;
        
        if (scrolled < window.innerHeight) {
            heroVisual.style.transform = `translateY(${rate}px)`;
        }
    });
}

// ============================================================================
// Form Validation
// ============================================================================
function validateEmail(email) {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
}

function validatePhone(phone) {
    const re = /^(\+91|91|0)?[6-9]\d{9}$/;
    return re.test(phone.replace(/[\s-]/g, ''));
}

// Add real-time validation to form inputs
document.querySelectorAll('.contact-form input, .contact-form textarea').forEach(input => {
    input.addEventListener('blur', function() {
        const value = this.value.trim();
        const type = this.type;
        const name = this.name;
        
        let isValid = true;
        
        if (this.required && !value) {
            isValid = false;
        } else if (type === 'email' && value && !validateEmail(value)) {
            isValid = false;
        } else if (name === 'phone' && value && !validatePhone(value)) {
            isValid = false;
        }
        
        this.style.borderColor = isValid ? '#EEEEEE' : '#F44336';
    });
    
    input.addEventListener('focus', function() {
        this.style.borderColor = '#2E7D32';
    });
});

// ============================================================================
// Feature Card Hover Effect
// ============================================================================
document.querySelectorAll('.feature-card').forEach(card => {
    card.addEventListener('mousemove', function(e) {
        const rect = this.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;
        
        this.style.setProperty('--mouse-x', `${x}px`);
        this.style.setProperty('--mouse-y', `${y}px`);
    });
});

// ============================================================================
// Scroll Progress Indicator
// ============================================================================
function createScrollProgress() {
    const progressBar = document.createElement('div');
    progressBar.className = 'scroll-progress';
    progressBar.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        height: 3px;
        background: linear-gradient(90deg, #2E7D32, #4CAF50);
        z-index: 9999;
        transition: width 0.1s ease;
        width: 0%;
    `;
    document.body.appendChild(progressBar);
    
    window.addEventListener('scroll', () => {
        const windowHeight = document.documentElement.scrollHeight - window.innerHeight;
        const scrolled = (window.scrollY / windowHeight) * 100;
        progressBar.style.width = `${scrolled}%`;
    });
}

createScrollProgress();

// ============================================================================
// Keyboard Navigation
// ============================================================================
document.addEventListener('keydown', (e) => {
    // ESC to close mobile menu
    if (e.key === 'Escape') {
        navLinks.classList.remove('active');
        mobileMenuBtn.classList.remove('active');
    }
});

// ============================================================================
// Performance: Debounce and Throttle
// ============================================================================
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

function throttle(func, limit) {
    let inThrottle;
    return function(...args) {
        if (!inThrottle) {
            func.apply(this, args);
            inThrottle = true;
            setTimeout(() => inThrottle = false, limit);
        }
    };
}

// ============================================================================
// Initialize on Load
// ============================================================================
window.addEventListener('load', () => {
    // Remove loading state if any
    document.body.classList.add('loaded');
    
    // Log welcome message
    console.log('%c🌱 AgriSense Pro', 'font-size: 24px; font-weight: bold; color: #2E7D32;');
    console.log('%cAI Crop Intelligence & Farmer Profit Engine', 'font-size: 14px; color: #757575;');
    console.log('%cBuilt with ❤️ for Indian Farmers', 'font-size: 12px; color: #FFA000;');
});
