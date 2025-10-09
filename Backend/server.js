const express = require("express");
const bodyParser = require("body-parser");
const mysql = require("mysql2");
const cors = require("cors");

const app = express();
const port = 3000;

app.use(bodyParser.json());
app.use(cors());

const pool = mysql.createPool({
  host: "10.83.211.100", // Changed from localhost to IP
  user: "root",
  password: "",
  database: "farmprecise",
  connectionLimit: 10,
  port: 3306
});

// Helper function to promisify database queries
const queryAsync = (query, params = []) => {
  return new Promise((resolve, reject) => {
    pool.query(query, params, (err, results) => {
      if (err) {
        reject(err);
      } else {
        resolve(results);
      }
    });
  });
};

// GET /community - Fetch all posts with replies and likes
app.get("/community", async (req, res) => {
  try {
    // First get all posts with their basic info and counts
    const postsQuery = `
      SELECT 
        id,
        USERNAME,
        TITLE,
        CONTENT,
        DATE,
        likes_count,
        comments_count
      FROM community 
      ORDER BY DATE DESC
    `;
    
    const posts = await queryAsync(postsQuery);
    
    // For each post, get its replies
    const postsWithReplies = await Promise.all(
      posts.map(async (post) => {
        const repliesQuery = `
          SELECT username, content, date
          FROM community_replies 
          WHERE post_id = ? 
          ORDER BY date ASC
        `;
        
        try {
          const replies = await queryAsync(repliesQuery, [post.id]);
          return {
            ...post,
            replies: replies || [],
            isLiked: false, // Default to false, you can implement user-specific logic later
            commentsCount: post.comments_count,
            likesCount: post.likes_count
          };
        } catch (replyErr) {
          console.error('Error fetching replies for post:', post.id, replyErr);
          return {
            ...post,
            replies: [],
            isLiked: false,
            commentsCount: post.comments_count || 0,
            likesCount: post.likes_count || 0
          };
        }
      })
    );
    
    res.json(postsWithReplies);
  } catch (error) {
    console.error('Error fetching posts:', error);
    res.status(500).json({ message: "Internal server error" });
  }
});

// POST /community - Add a new community post
app.post("/community", async (req, res) => {
  try {
    const { USERNAME, TITLE, CONTENT, DATE, likesCount } = req.body;

    const insertQuery = `
      INSERT INTO community (USERNAME, TITLE, CONTENT, DATE, likes_count, comments_count) 
      VALUES (?, ?, ?, ?, ?, 0)
    `;

    const result = await queryAsync(insertQuery, [
      USERNAME, 
      TITLE, 
      CONTENT, 
      DATE, 
      likesCount || Math.floor(Math.random() * 51) // Random likes 0-50 if not provided
    ]);

    res.status(201).json({ 
      message: "Post added successfully",
      postId: result.insertId 
    });
  } catch (error) {
    console.error("Error adding post:", error);
    res.status(500).json({ message: "Internal server error" });
  }
});

// POST /community/:postId/like - Toggle like for a post
app.post("/community/:postId/like", async (req, res) => {
  try {
    const { postId } = req.params;
    const { username, action } = req.body; // action can be 'like' or 'unlike'
    
    if (action === 'like') {
      // Check if user already liked this post
      const existingLikeQuery = `
        SELECT id FROM community_likes 
        WHERE post_id = ? AND username = ?
      `;
      
      const existingLike = await queryAsync(existingLikeQuery, [postId, username]);
      
      if (existingLike.length === 0) {
        // User hasn't liked yet, so add like
        await queryAsync(
          'INSERT INTO community_likes (post_id, username) VALUES (?, ?)',
          [postId, username]
        );
        await queryAsync(
          'UPDATE community SET likes_count = likes_count + 1 WHERE id = ?',
          [postId]
        );
        
        res.json({ success: true, action: 'liked', liked: true });
      } else {
        res.json({ success: true, action: 'already_liked', liked: true });
      }
    } else if (action === 'unlike') {
      // Remove like
      await queryAsync(
        'DELETE FROM community_likes WHERE post_id = ? AND username = ?',
        [postId, username]
      );
      await queryAsync(
        'UPDATE community SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = ?',
        [postId]
      );
      
      res.json({ success: true, action: 'unliked', liked: false });
    } else {
      res.status(400).json({ error: 'Invalid action. Use "like" or "unlike"' });
    }
  } catch (error) {
    console.error('Error toggling like:', error);
    res.status(500).json({ message: "Internal server error" });
  }
});

// POST /community/:postId/reply - Add reply to a post
app.post("/community/:postId/reply", async (req, res) => {
  try {
    const { postId } = req.params;
    const { username, content } = req.body;
    
    // Insert the reply
    const insertReplyQuery = `
      INSERT INTO community_replies (post_id, username, content, date)
      VALUES (?, ?, ?, NOW())
    `;
    
    await queryAsync(insertReplyQuery, [postId, username, content]);
    
    // Update the comments count in the main post
    await queryAsync(
      'UPDATE community SET comments_count = comments_count + 1 WHERE id = ?',
      [postId]
    );
    
    res.status(201).json({ 
      success: true, 
      message: 'Reply added successfully' 
    });
  } catch (error) {
    console.error('Error adding reply:', error);
    res.status(500).json({ message: "Internal server error" });
  }
});

// GET /community/:postId/replies - Get all replies for a specific post
app.get("/community/:postId/replies", async (req, res) => {
  try {
    const { postId } = req.params;
    
    const repliesQuery = `
      SELECT username, content, date
      FROM community_replies 
      WHERE post_id = ? 
      ORDER BY date ASC
    `;
    
    const replies = await queryAsync(repliesQuery, [postId]);
    
    res.json(replies);
  } catch (error) {
    console.error('Error fetching replies:', error);
    res.status(500).json({ message: "Internal server error" });
  }
});

// GET /community/:postId/likes/:username - Check if user liked a post
app.get("/community/:postId/likes/:username", async (req, res) => {
  try {
    const { postId, username } = req.params;
    
    const likeStatusQuery = `
      SELECT 
        c.likes_count,
        CASE WHEN cl.id IS NOT NULL THEN TRUE ELSE FALSE END as is_liked
      FROM community c
      LEFT JOIN community_likes cl ON c.id = cl.post_id AND cl.username = ?
      WHERE c.id = ?
    `;
    
    const result = await queryAsync(likeStatusQuery, [username, postId]);
    
    if (result.length > 0) {
      res.json({
        likes_count: result[0].likes_count,
        is_liked: Boolean(result[0].is_liked)
      });
    } else {
      res.status(404).json({ error: 'Post not found' });
    }
  } catch (error) {
    console.error('Error fetching like status:', error);
    res.status(500).json({ message: "Internal server error" });
  }
});

// Existing routes (login, signup, farmsetup, croprecommendation)
app.post("/login", (req, res) => {
  const { USERNAME, PASSWORD } = req.body;

  pool.query(
    "SELECT * FROM user WHERE USERNAME = ? AND PASSWORD = ?",
    [USERNAME, PASSWORD],
    (err, results) => {
      if (err) {
        console.error("Error executing query:", err);
        res.status(500).json({ message: "Internal server error" });
        return;
      }

      if (results.length === 0) {
        res.status(401).json({ message: "Invalid credentials" });
        return;
      }

      // If login is successful, return user data
      const user = {
        USERNAME: results[0].USERNAME,
      };
      res.json(user);
    }
  );
});

app.post("/signup", (req, res) => {
  const { USERNAME, EMAIL, PASSWORD } = req.body;

  pool.query(
    "INSERT INTO user (USERNAME, EMAIL, PASSWORD) VALUES (?, ?, ?)",
    [USERNAME, EMAIL, PASSWORD],
    (err, results) => {
      if (err) {
        console.error("Error executing query:", err);
        res.status(500).json({ message: "Internal server error" });
        return;
      }

      // Signup successful
      res.status(201).json({ message: "Signup successful" });
    }
  );
});

app.post("/farmsetup", (req, res) => {
  const {
    FARMERNAME,
    LOCALITY,
    ACRES,
    SOILTYPE,
    WATERSOURCE,
    CURRENTCROP,
    PASTCROP,
  } = req.body;

  pool.query(
    "INSERT INTO farm (FARMERNAME, LOCALITY, ACRES, SOILTYPE, WATERSOURCE, CURRENTCROP, PASTCROP) VALUES (?, ?, ?, ?, ?, ?, ?)",
    [FARMERNAME, LOCALITY, ACRES, SOILTYPE, WATERSOURCE, CURRENTCROP, PASTCROP],
    (err, results) => {
      if (err) {
        console.error("Error executing query:", err);
        res.status(500).json({ message: "Internal server error" });
        return;
      }

      // Farm setup successful
      res.status(201).json({ message: "Farm setup successful" });
    }
  );
});

app.get("/croprecommendation", (req, res) => {
  const selectQuery =
    "SELECT Location, Temperature, Humidity, Recommended_Crop ,Days_Required,Water_Needed,Crop_Image FROM crop_recommendation WHERE Location = 'Sathyamangalam'";

  pool.query(selectQuery, (err, results) => {
    if (err) {
      console.error("Error executing query:", err);
      res.status(500).json({ message: "Internal server error" });
      return;
    }
    res.json(results);
  });
});

app.listen(port, () => {
  console.log(`Server is running on 10.83.211.100:${port}`);
});