-- users table

CREATE TABLE IF NOT EXISTS "new_users" (
		"id" SERIAL PRIMARY KEY,
		"username" VARCHAR(25) UNIQUE NOT NULL,	
		"last_login" TIMESTAMP WITH TIME ZONE,
		CONSTRAINT "no_blank_username"
			CHECK (LENGTH(TRIM("username"))>0)
);

-- topics table

CREATE TABLE IF NOT EXISTS "new_topics" (
		"id" SERIAL PRIMARY KEY,
		"topic_name" VARCHAR(30) UNIQUE NOT NULL,	
		"topic_desc" VARCHAR(500),
		CONSTRAINT "no_blank_topic" 
			CHECK (LENGTH(TRIM("topic_name"))>0)
);

-- posts table

CREATE TABLE IF NOT EXISTS "new_posts" (
		"id" SERIAL PRIMARY KEY NOT NULL,
		"user_id" INT,
		"topic_id" INT NOT NULL,
		"post_title" VARCHAR(100) NOT NULL,
		"url" VARCHAR,
		"post_content" VARCHAR,
		"post_dt" TIMESTAMP WITH TIME ZONE,
		CONSTRAINT "user_id_fk" FOREIGN KEY ("user_id") 
			REFERENCES "new_users"("id") ON DELETE SET NULL,
		CONSTRAINT "topic_id_fk" FOREIGN KEY ("topic_id") 
			REFERENCES "new_topics"("id") ON DELETE CASCADE,
		CONSTRAINT "url_post_content_fk" 
			CHECK (("url" IS NULL AND "post_content" IS NOT NULL) 
			   OR ("url" IS NOT NULL AND "post_content" IS NULL)),
		CONSTRAINT "no_blank_post" 
			CHECK (LENGTH(TRIM("post_title"))>0)
		);


--comments table

CREATE TABLE IF NOT EXISTS "new_comments" (
		"id" SERIAL PRIMARY KEY,
		"comment_content" VARCHAR,
		"user_id" INT NOT NULL,
		"post_id" INT NOT NULL,
		"comment_id" INT,
		"comment_dt" TIMESTAMP WITH TIME ZONE,
		CONSTRAINT "comment_id_fk" FOREIGN KEY ("comment_id") 
			REFERENCES "new_comments"("id") ON DELETE CASCADE,
		CONSTRAINT "no_blank_comment" 
			CHECK (LENGTH(TRIM("comment_content"))>0)
		);

--votes table

CREATE TABLE IF NOT EXISTS "new_votes" (
		"id" SERIAL PRIMARY KEY,
		"post_id" INT NOT NULL,
		"user_id" INT,
		"vote_value" INT,
		CONSTRAINT "user_id_fk" FOREIGN KEY ("user_id") 
			REFERENCES "new_users"("id") ON DELETE SET NULL,
		CONSTRAINT "post_id_fk" FOREIGN KEY ("post_id") 
			REFERENCES "new_posts"("id") ON DELETE CASCADE,
		CONSTRAINT "vote_value" 
			CHECK (("vote_value" = 1) OR ("vote_value" = -1)),
		CONSTRAINT "unique_vote" 
			UNIQUE ("user_id", "post_id")	
		);

CREATE INDEX "users_post" 
	ON "new_posts" ("user_id");
	
CREATE INDEX "posts_url" 
	ON "new_posts" ("url");
	
CREATE INDEX "posts_topic" 
	ON "new_posts" ("topic_id");
	
CREATE INDEX "main_comments" 
	ON "new_comments" ("comment_id");
	
CREATE INDEX "user_comments" 
	ON "new_comments" ("user_id");
	
CREATE INDEX "votes_cnt" 
	ON "new_votes" ("vote_value");


-- insert user data into the new users table

INSERT INTO "new_users" ("username")

	SELECT DISTINCT "username" 
		FROM "bad_comments"
UNION
	SELECT "username" 
		FROM "bad_posts"
UNION
	SELECT DISTINCT regexp_split_to_table("upvotes",',') 
		FROM "bad_posts"
UNION
	SELECT DISTINCT regexp_split_to_table("downvotes",',') 
		FROM "bad_posts";
	
--11077

SELECT COUNT("username") FROM "new_users";

INSERT INTO "new_topics"("topic_name")
	SELECT DISTINCT "topic"
		FROM "bad_posts";
		
--89

SELECT COUNT("topic_name") FROM "new_topics";

INSERT INTO "new_posts"("post_title", "url", "post_content", "user_id", "topic_id")

		SELECT LEFT("bp"."title", 100) AS "title", 
		"bp"."url", 
		"bp"."text_content", 
		"u"."id", 
		"tp"."id"
		
		FROM "bad_posts" "bp"
			
		JOIN "new_users" "u"
			ON "bp"."username" = "u"."username"
			
		JOIN "new_topics" "tp"
			ON "bp"."topic" = "tp"."topic_name";

--50000

SELECT COUNT("post_title") FROM "new_posts";

INSERT INTO "new_comments" ("user_id", "post_id", "comment_content")
	SELECT "np"."user_id", 
		"u"."id", 
		"bc"."text_content"
		
	FROM "bad_comments" "bc"

	JOIN "new_users" "u"
		ON "u"."username" = "bc"."username"
		
	JOIN "new_posts" "np"
		ON "np"."id" = "bc"."post_id";

--100000

SELECT COUNT("user_id") FROM "new_comments";

INSERT INTO "new_votes" ("user_id","post_id","vote_value")

SELECT 		"u"."id" AS "user_id",
			"a"."id" AS "post_id",
			-1 AS "downvotes"
FROM (
			
			SELECT REGEXP_SPLIT_TO_TABLE("downvotes", ',') AS "username",
					"bp"."id"			
			FROM "bad_posts" "bp"
	 ) AS "a"

JOIN "new_users" "u"
	ON "u"."username" = "a"."username"
	
JOIN "new_posts" "np"
	ON "np"."id"="a"."id"

UNION

			SELECT "u"."id" AS "user_id",
			"b"."id" AS "post_id",
			1 AS "downvotes"
			
		FROM (
			
		SELECT REGEXP_SPLIT_TO_TABLE("upvotes", ',') AS "username",
				"bp"."id"			
					FROM "bad_posts" "bp"
		) AS "b"

JOIN "new_users" "u"
	ON "u"."username" = "b"."username"
	
JOIN "new_posts" "np"
	ON "np"."id"="b"."id"
	
ON CONFLICT DO NOTHING;

-- 499710

SELECT COUNT("vote_value") FROM "new_votes";

