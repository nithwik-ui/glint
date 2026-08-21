import express from 'express';

const router = express.Router();

// NSFW and explicit keyword blacklist
const BLACKLISTED_KEYWORDS = [
  'nsfw', 'sexy', 'porn', 'naked', 'adult', 'xxx', 'gore', 'kill', 'suicide', 'death', 'blood',
  'hentai', 'erotic', 'nude', 'vagina', 'penis', 'breasts', 'boobs', 'ass', 'butt', 'weed', 'drugs',
  'cocaine', 'marijuana', 'violence', 'murder', 'terrorist', 'hitler', 'swastika', 'racist'
];

// Helper: Check if text contains blacklisted keywords
function containsUnsafeContent(text) {
  if (!text) return false;
  const normalizedText = text.toLowerCase();
  return BLACKLISTED_KEYWORDS.some(keyword => normalizedText.includes(keyword));
}

// Helper: Filter safe wallpapers from list
function filterSafeWallpapers(wallpapers) {
  return wallpapers.filter(wp => {
    if (containsUnsafeContent(wp.title)) return false;
    if (containsUnsafeContent(wp.author)) return false;
    if (wp.tags && wp.tags.some(tag => containsUnsafeContent(tag))) return false;
    return true;
  });
}

// Helper: Ensure hex color string format starts with exactly one #
function cleanHexColor(c) {
  if (!c) return '#8127cf';
  if (c.startsWith('##')) return c.substring(1);
  return c.startsWith('#') ? c : `#${c}`;
}

// Fetch with a timeout signal
async function fetchWithTimeout(url, options = {}, timeoutMs = 1500) {
  const controller = new AbortController();
  const id = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(url, { ...options, signal: controller.signal });
    clearTimeout(id);
    return response;
  } catch (error) {
    clearTimeout(id);
    throw error;
  }
}

// Synonym dictionary mapping
const SYNONYMS = {
  'space': ['galaxy', 'universe', 'stars', 'planets', 'astronomy', 'cosmos', 'nebula', 'milky way', 'apod', 'astronaut', 'sky', 'night sky'],
  'galaxy': ['space', 'universe', 'cosmos', 'nebula'],
  'nebula': ['space', 'galaxy', 'universe', 'cosmos'],
  'universe': ['space', 'galaxy', 'cosmos', 'nebula'],
  'nature': ['landscape', 'forest', 'mountain', 'lake', 'river', 'sea', 'ocean', 'beach', 'trees', 'sunset', 'sunrise'],
  'minimal': ['minimalist', 'clean', 'simple', 'flat', 'vector'],
  'abstract': ['gradient', 'fluid', 'liquid', 'art', 'vector', 'digital'],
  'anime': ['manga', 'japanese', 'illustration', 'art'],
  'sports': ['gaming', 'football', 'basketball', 'soccer', 'racing', 'cars', 'pulse'],
  'amoled': ['dark', 'black', 'oled', 'neon']
};

const KNOWN_WORDS = ['space', 'nature', 'minimal', 'abstract', 'anime', 'sports', 'amoled', 'galaxy', 'universe', 'stars', 'planets', 'astronomy', 'cosmos', 'nebula', 'milky way'];

// Levenshtein distance for typo tolerance
function levenshteinDistance(s1, s2) {
  const len1 = s1.length, len2 = s2.length;
  const matrix = Array.from({ length: len1 + 1 }, () => Array(len2 + 1).fill(0));
  for (let i = 0; i <= len1; i++) matrix[i][0] = i;
  for (let j = 0; j <= len2; j++) matrix[0][j] = j;
  for (let i = 1; i <= len1; i++) {
    for (let j = 1; j <= len2; j++) {
      const cost = s1[i - 1] === s2[j - 1] ? 0 : 1;
      matrix[i][j] = Math.min(
        matrix[i - 1][j] + 1, // deletion
        matrix[i][j - 1] + 1, // insertion
        matrix[i - 1][j - 1] + cost // substitution
      );
    }
  }
  return matrix[len1][len2];
}

// Typo correction logic
function correctTypos(query) {
  if (!query) return '';
  const words = query.toLowerCase().split(/\s+/);
  const corrected = words.map(word => {
    if (word.length < 3) return word;
    if (KNOWN_WORDS.includes(word)) return word;
    let bestMatch = word;
    let minDistance = 999;
    for (const known of KNOWN_WORDS) {
      const maxDist = word.length <= 4 ? 1 : 2;
      const d = levenshteinDistance(word, known);
      if (d <= maxDist && d < minDistance) {
        minDistance = d;
        bestMatch = known;
      }
    }
    return bestMatch;
  });
  return corrected.join(' ');
}

// Synonym expansion query builder
function getExpandedQueries(query) {
  const corrected = correctTypos(query);
  const words = corrected.split(/\s+/);
  const queries = [corrected];
  
  words.forEach(word => {
    if (SYNONYMS[word]) {
      queries.push(...SYNONYMS[word]);
    }
  });
  
  return [...new Set(queries)].slice(0, 5);
}

// Static Handpicked Premium Fallback Wallpapers (Royalty-free high-res)
const STATIC_FALLBACK_WALLPAPERS = [
  {
    id: "fallback_1",
    provider: "fallback",
    title: "Celestial Ridge",
    author: "Glint Curator",
    thumbnailUrl: "https://images.unsplash.com/photo-1506318137071-a8e063b4bec0?auto=format&fit=crop&w=400&q=80",
    previewUrl: "https://images.unsplash.com/photo-1506318137071-a8e063b4bec0?auto=format&fit=crop&w=1080&q=80",
    fullUrl: "https://images.unsplash.com/photo-1506318137071-a8e063b4bec0",
    width: 1920,
    height: 1080,
    color: "#0e0b16",
    colors: ["#0e0b16", "#8127cf"],
    tags: ["space", "galaxy", "minimal", "dark"]
  },
  {
    id: "fallback_2",
    provider: "fallback",
    title: "Emerald Forest",
    author: "Glint Curator",
    thumbnailUrl: "https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=400&q=80",
    previewUrl: "https://images.unsplash.com/photo-1448375240586-882707db888b?auto=format&fit=crop&w=1080&q=80",
    fullUrl: "https://images.unsplash.com/photo-1448375240586-882707db888b",
    width: 1920,
    height: 1280,
    color: "#059669",
    colors: ["#059669", "#0e0b16"],
    tags: ["nature", "forest", "green", "minimal"]
  },
  {
    id: "fallback_3",
    provider: "fallback",
    title: "Ocean Whisper",
    author: "Glint Curator",
    thumbnailUrl: "https://images.unsplash.com/photo-1505118380757-91f5f5632de0?auto=format&fit=crop&w=400&q=80",
    previewUrl: "https://images.unsplash.com/photo-1505118380757-91f5f5632de0?auto=format&fit=crop&w=1080&q=80",
    fullUrl: "https://images.unsplash.com/photo-1505118380757-91f5f5632de0",
    width: 1920,
    height: 1280,
    color: "#0284c7",
    colors: ["#0284c7", "#f5eaf8"],
    tags: ["ocean", "beach", "blue", "nature"]
  },
  {
    id: "fallback_4",
    provider: "fallback",
    title: "Abstract Flow",
    author: "Glint Curator",
    thumbnailUrl: "https://images.unsplash.com/photo-1541701494587-cb58502866ab?auto=format&fit=crop&w=400&q=80",
    previewUrl: "https://images.unsplash.com/photo-1541701494587-cb58502866ab?auto=format&fit=crop&w=1080&q=80",
    fullUrl: "https://images.unsplash.com/photo-1541701494587-cb58502866ab",
    width: 1920,
    height: 1280,
    color: "#8127cf",
    colors: ["#8127cf", "#ffdead"],
    tags: ["abstract", "gradient", "aesthetic"]
  },
  {
    id: "fallback_5",
    provider: "fallback",
    title: "Minimalist Dome",
    author: "Glint Curator",
    thumbnailUrl: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=400&q=80",
    previewUrl: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1080&q=80",
    fullUrl: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c",
    width: 1920,
    height: 1280,
    color: "#f5eaf8",
    colors: ["#f5eaf8", "#7e7385"],
    tags: ["architecture", "minimal", "aesthetic"]
  },
  {
    id: "fallback_6",
    provider: "fallback",
    title: "Cyber Neon",
    author: "Glint Curator",
    thumbnailUrl: "https://images.unsplash.com/photo-1508739773434-c26b3d09e071?auto=format&fit=crop&w=400&q=80",
    previewUrl: "https://images.unsplash.com/photo-1508739773434-c26b3d09e071?auto=format&fit=crop&w=1080&q=80",
    fullUrl: "https://images.unsplash.com/photo-1508739773434-c26b3d09e071",
    width: 1920,
    height: 1280,
    color: "#0e0b16",
    colors: ["#0e0b16", "#8127cf"],
    tags: ["cyberpunk", "neon", "dark", "technology"]
  },
  {
    id: "fallback_7",
    provider: "fallback",
    title: "Mountain Solitude",
    author: "Glint Curator",
    thumbnailUrl: "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=400&q=80",
    previewUrl: "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=1080&q=80",
    fullUrl: "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b",
    width: 1920,
    height: 1280,
    color: "#0284c7",
    colors: ["#0284c7", "#059669"],
    tags: ["nature", "mountains", "forest"]
  },
  {
    id: "fallback_8",
    provider: "fallback",
    title: "Sports Pulse",
    author: "Glint Curator",
    thumbnailUrl: "https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&w=400&q=80",
    previewUrl: "https://images.unsplash.com/photo-1508098682722-e99c43a406b2?auto=format&fit=crop&w=1080&q=80",
    fullUrl: "https://images.unsplash.com/photo-1508098682722-e99c43a406b2",
    width: 1920,
    height: 1280,
    color: "#ba1a1a",
    colors: ["#ba1a1a", "#000000"],
    tags: ["sports", "gaming", "neon"]
  },
  {
    id: "fallback_9",
    provider: "fallback",
    title: "Supercar Stealth",
    author: "Glint Curator",
    thumbnailUrl: "https://images.unsplash.com/photo-1617814076367-b759c7d7e738?auto=format&fit=crop&w=400&q=80",
    previewUrl: "https://images.unsplash.com/photo-1617814076367-b759c7d7e738?auto=format&fit=crop&w=1080&q=80",
    fullUrl: "https://images.unsplash.com/photo-1617814076367-b759c7d7e738",
    width: 1920,
    height: 1280,
    color: "#1f1a23",
    colors: ["#1f1a23", "#ba1a1a"],
    tags: ["cars", "supercars", "luxury"]
  },
  {
    id: "fallback_10",
    provider: "fallback",
    title: "Vintage Vibe",
    author: "Glint Curator",
    thumbnailUrl: "https://images.unsplash.com/photo-1513829096960-ef2297c37add?auto=format&fit=crop&w=400&q=80",
    previewUrl: "https://images.unsplash.com/photo-1513829096960-ef2297c37add?auto=format&fit=crop&w=1080&q=80",
    fullUrl: "https://images.unsplash.com/photo-1513829096960-ef2297c37add",
    width: 1920,
    height: 1280,
    color: "#7b5500",
    colors: ["#7b5500", "#ffdead"],
    tags: ["retro", "vintage", "classic"]
  }
];

// Router Endpoint: Curated / Trending Wallpapers
router.get('/curated', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const perPage = parseInt(req.query.per_page) || 20;

    let combined = [];
    const promises = [];

    // --- Provider 1: Pexels ---
    if (process.env.PEXELS_API_KEY) {
      promises.push(
        fetchWithTimeout(`https://api.pexels.com/v1/curated?page=${page}&per_page=${perPage}`, {
          headers: { 'Authorization': process.env.PEXELS_API_KEY }
        }, 1500)
        .then(async response => {
          if (!response.ok) throw new Error(`Pexels API error status: ${response.status}`);
          const data = await response.json();
          const photos = data.photos || [];
          return photos.map(photo => ({
            id: `pexels_${photo.id}`,
            provider: 'pexels',
            title: photo.alt || 'Glint Exclusive',
            author: photo.photographer || 'Anonymous',
            thumbnailUrl: photo.src.small || photo.src.medium,
            previewUrl: photo.src.large2x || photo.src.large,
            fullUrl: photo.src.original,
            width: photo.width,
            height: photo.height,
            color: photo.avg_color || '#8127cf',
            colors: [photo.avg_color || '#8127cf'],
            tags: photo.alt ? photo.alt.split(' ').filter(w => w.length > 3) : ['nature', 'wallpaper']
          }));
        })
        .catch(e => {
          console.error("Error fetching from Pexels (failover active):", e.message);
          return [];
        })
      );
    }

    // --- Provider 2: Wallhaven ---
    promises.push(
      (() => {
        const wallhavenKey = process.env.WALLHAVEN_API_KEY;
        const url = wallhavenKey 
            ? `https://wallhaven.cc/api/v1/search?apikey=${wallhavenKey}&purity=100&sorting=toplist&page=${page}`
            : `https://wallhaven.cc/api/v1/search?purity=100&sorting=toplist&page=${page}`;
        return fetchWithTimeout(url, {}, 1500)
          .then(async response => {
            if (!response.ok) throw new Error(`Wallhaven API error status: ${response.status}`);
            const data = await response.json();
            const photos = data.data || [];
            return photos.map(photo => ({
              id: `wallhaven_${photo.id}`,
              provider: 'wallhaven',
              title: photo.id,
              author: 'Wallhaven Artist',
              thumbnailUrl: photo.thumbs.small || photo.thumbs.large,
              previewUrl: photo.path,
              fullUrl: photo.path,
              width: photo.dimension_x,
              height: photo.dimension_y,
              color: photo.colors && photo.colors.length > 0 ? cleanHexColor(photo.colors[0]) : '#8127cf',
              colors: photo.colors ? photo.colors.map(cleanHexColor) : [],
              tags: photo.category ? [photo.category] : ['aesthetic']
            }));
          })
          .catch(e => {
            console.error("Error fetching from Wallhaven (failover active):", e.message);
            return [];
          });
      })()
    );

    // --- Provider 3: Pixabay ---
    if (process.env.PIXABAY_API_KEY) {
      promises.push(
        fetchWithTimeout(`https://pixabay.com/api/?key=${process.env.PIXABAY_API_KEY}&q=wallpaper+background&page=${page}&per_page=${perPage}&image_type=photo&orientation=vertical&safesearch=true`, {}, 1500)
        .then(async response => {
          if (!response.ok) throw new Error(`Pixabay API error status: ${response.status}`);
          const data = await response.json();
          const hits = data.hits || [];
          return hits.map(photo => ({
            id: `pixabay_${photo.id}`,
            provider: 'pixabay',
            title: photo.tags ? photo.tags.split(',')[0] : 'Glint Creative',
            author: photo.user || 'Pixabay Creator',
            thumbnailUrl: photo.previewURL,
            previewUrl: photo.webformatURL,
            fullUrl: photo.largeImageURL,
            width: photo.imageWidth,
            height: photo.imageHeight,
            color: '#8127cf',
            colors: [],
            tags: photo.tags ? photo.tags.split(',').map(t => t.trim()) : []
          }));
        })
        .catch(e => {
          console.error("Error fetching from Pixabay (failover active):", e.message);
          return [];
        })
      );
    }

    // Execute in parallel
    const results = await Promise.all(promises);
    results.forEach(arr => combined.push(...arr));

    // --- Provider 4: Picsum Photos (as failover) ---
    if (combined.length === 0) {
      try {
        const response = await fetchWithTimeout(`https://picsum.photos/v2/list?page=${page}&limit=${perPage}`, {}, 1500);
        if (response.ok) {
          const data = await response.json();
          combined.push(...data.map(photo => ({
            id: `picsum_${photo.id}`,
            provider: 'picsum',
            title: 'Aesthetic Art',
            author: photo.author,
            thumbnailUrl: `https://picsum.photos/id/${photo.id}/400/800`,
            previewUrl: `https://picsum.photos/id/${photo.id}/1080/1920`,
            fullUrl: `https://picsum.photos/id/${photo.id}/1440/2560`,
            width: 1440,
            height: 2560,
            color: '#8127cf',
            colors: ['#8127cf'],
            tags: ['picsum', 'aesthetic', 'minimal']
          })));
        }
      } catch (e) {
        console.error("Error fetching from Picsum (failover active):", e.message);
      }
    }

    // --- Final Fallback: Local Handpicked Static Premium ---
    if (combined.length === 0) {
      combined.push(...STATIC_FALLBACK_WALLPAPERS);
    }

    // Shuffle slightly to make feed dynamic and premium
    combined.sort(() => Math.random() - 0.5);

    // Apply strict safe filter
    const safeCombined = filterSafeWallpapers(combined);

    res.json({
      page,
      per_page: perPage,
      total_results: safeCombined.length,
      wallpapers: safeCombined
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch curated wallpapers', details: error.message });
  }
});

// Router Endpoint: Search Wallpapers
router.get('/search', async (req, res) => {
  try {
    const query = req.query.query || '';
    const color = req.query.color || '';
    const category = req.query.category || '';
    const page = parseInt(req.query.page) || 1;
    const perPage = parseInt(req.query.per_page) || 20;

    // Strict validation
    if (containsUnsafeContent(query) || containsUnsafeContent(category) || containsUnsafeContent(color)) {
      return res.status(400).json({ error: 'Search query contains inappropriate or unsafe content' });
    }

    const correctedQuery = correctTypos(query);
    const expandedTerms = getExpandedQueries(correctedQuery);

    let searchQuery = correctedQuery;
    if (category && category !== 'All') {
      searchQuery = searchQuery ? `${category} ${searchQuery}` : category;
    }

    // Combine top terms for richer provider results
    let providerSearchQuery = searchQuery;
    if (expandedTerms.length > 0 && searchQuery) {
      providerSearchQuery = expandedTerms.slice(0, 3).join(' ');
      if (category && category !== 'All') {
        providerSearchQuery = `${category} ${providerSearchQuery}`;
      }
    }

    let combined = [];
    const promises = [];

    // 1. Fetch from Pexels
    if (process.env.PEXELS_API_KEY && providerSearchQuery) {
      let url = `https://api.pexels.com/v1/search?query=${encodeURIComponent(providerSearchQuery)}&page=${page}&per_page=${perPage}`;
      if (color) {
        url += `&color=${encodeURIComponent(color)}`;
      }
      promises.push(
        fetchWithTimeout(url, {
          headers: { 'Authorization': process.env.PEXELS_API_KEY }
        }, 1500)
        .then(async response => {
          if (!response.ok) throw new Error(`Pexels API error status: ${response.status}`);
          const data = await response.json();
          const photos = data.photos || [];
          return photos.map(photo => ({
            id: `pexels_${photo.id}`,
            provider: 'pexels',
            title: photo.alt || 'Glint Exclusive',
            author: photo.photographer || 'Anonymous',
            thumbnailUrl: photo.src.small || photo.src.medium,
            previewUrl: photo.src.large2x || photo.src.large,
            fullUrl: photo.src.original,
            width: photo.width,
            height: photo.height,
            color: photo.avg_color || '#8127cf',
            colors: [photo.avg_color || '#8127cf'],
            tags: photo.alt ? photo.alt.split(' ').filter(w => w.length > 3) : ['nature']
          }));
        })
        .catch(e => {
          console.error("Pexels search error (failover active):", e.message);
          return [];
        })
      );
    }

    // 2. Fetch from Wallhaven
    promises.push(
      (() => {
        const wallhavenKey = process.env.WALLHAVEN_API_KEY;
        let wallhavenUrl = wallhavenKey
            ? `https://wallhaven.cc/api/v1/search?apikey=${wallhavenKey}&purity=100&page=${page}`
            : `https://wallhaven.cc/api/v1/search?purity=100&page=${page}`;
        if (providerSearchQuery) {
          wallhavenUrl += `&q=${encodeURIComponent(providerSearchQuery)}`;
        }
        if (color) {
          const cleanColor = color.replace('#', '');
          wallhavenUrl += `&colors=${cleanColor}`;
        }
        return fetchWithTimeout(wallhavenUrl, {}, 1500)
          .then(async response => {
            if (!response.ok) throw new Error(`Wallhaven API error status: ${response.status}`);
            const data = await response.json();
            const photos = data.data || [];
            return photos.map(photo => ({
              id: `wallhaven_${photo.id}`,
              provider: 'wallhaven',
              title: photo.id,
              author: 'Wallhaven Artist',
              thumbnailUrl: photo.thumbs.small || photo.thumbs.large,
              previewUrl: photo.path,
              fullUrl: photo.path,
              width: photo.dimension_x,
              height: photo.dimension_y,
              color: photo.colors && photo.colors.length > 0 ? cleanHexColor(photo.colors[0]) : '#8127cf',
              colors: photo.colors ? photo.colors.map(cleanHexColor) : [],
              tags: photo.category ? [photo.category] : ['aesthetic']
            }));
          })
          .catch(e => {
            console.error("Wallhaven search error (failover active):", e.message);
            return [];
          });
      })()
    );

    // 3. Fetch from Pixabay
    if (process.env.PIXABAY_API_KEY && providerSearchQuery) {
      let pixabayUrl = `https://pixabay.com/api/?key=${process.env.PIXABAY_API_KEY}&q=${encodeURIComponent(providerSearchQuery)}&page=${page}&per_page=${perPage}&image_type=photo&orientation=vertical&safesearch=true`;
      if (color) {
        pixabayUrl += `&colors=${color}`;
      }
      promises.push(
        fetchWithTimeout(pixabayUrl, {}, 1500)
        .then(async response => {
          if (!response.ok) throw new Error(`Pixabay API error status: ${response.status}`);
          const data = await response.json();
          const hits = data.hits || [];
          return hits.map(photo => ({
            id: `pixabay_${photo.id}`,
            provider: 'pixabay',
            title: photo.tags ? photo.tags.split(',')[0] : 'Glint Creative',
            author: photo.user || 'Pixabay Creator',
            thumbnailUrl: photo.previewURL,
            previewUrl: photo.webformatURL,
            fullUrl: photo.largeImageURL,
            width: photo.imageWidth,
            height: photo.imageHeight,
            color: '#8127cf',
            colors: [],
            tags: photo.tags ? photo.tags.split(',').map(t => t.trim()) : []
          }));
        })
        .catch(e => {
          console.error("Pixabay search error (failover active):", e.message);
          return [];
        })
      );
    }

    // Execute in parallel
    const results = await Promise.all(promises);
    results.forEach(arr => combined.push(...arr));

    // 4. Fallback search (always match against local static wallpapers with synonyms & corrected terms)
    const searchTerms = searchQuery ? searchQuery.toLowerCase().split(' ') : [];
    const allTermsToSearch = [...new Set([...searchTerms, ...expandedTerms.map(t => t.toLowerCase())])];

    const matched = STATIC_FALLBACK_WALLPAPERS.filter(wp => {
      if (!searchQuery) return true;
      return wp.tags.some(tag => allTermsToSearch.some(term => tag.toLowerCase().includes(term))) ||
             wp.title.toLowerCase().includes(correctedQuery.toLowerCase()) ||
             wp.title.toLowerCase().includes(query.toLowerCase());
    });

    if (matched.length > 0) {
      if (combined.length === 0) {
        combined.push(...matched);
      } else {
        // Interleave fallback matches
        combined.unshift(...matched.slice(0, 3));
      }
    }

    if (combined.length === 0) {
      combined.push(...STATIC_FALLBACK_WALLPAPERS);
    }

    const safeCombined = filterSafeWallpapers(combined);

    res.json({
      page,
      per_page: perPage,
      total_results: safeCombined.length,
      wallpapers: safeCombined
    });
  } catch (error) {
    res.status(500).json({ error: 'Search failed', details: error.message });
  }
});

// Router Endpoint: NASA APOD (Wallpaper of the Day)
router.get('/apod', async (req, res) => {
  try {
    const apiKey = process.env.NASA_API_KEY || 'DEMO_KEY';
    const response = await fetch(`https://api.nasa.gov/planetary/apod?api_key=${apiKey}`);
    
    if (response.ok) {
      const data = await response.json();
      if (data.media_type === 'image') {
        const formattedApod = {
          id: `nasa_apod_${data.date}`,
          provider: 'nasa',
          title: data.title || 'Cosmic Refraction',
          author: data.copyright || 'NASA Space Center',
          thumbnailUrl: data.url,
          previewUrl: data.hdurl || data.url,
          fullUrl: data.hdurl || data.url,
          width: 1920,
          height: 1080,
          color: '#0e0b16',
          colors: ['#0e0b16', '#8127cf'],
          tags: ['space', 'nasa', 'astronomy', 'stars', 'galaxy', 'nebula'],
          explanation: data.explanation
        };
        return res.json(formattedApod);
      }
    }

    // APOD fail fallback
    const spaceFallback = STATIC_FALLBACK_WALLPAPERS.find(wp => wp.tags.includes('space')) || STATIC_FALLBACK_WALLPAPERS[0];
    res.json(spaceFallback);
  } catch (error) {
    res.json(STATIC_FALLBACK_WALLPAPERS[0]);
  }
});

export default router;
