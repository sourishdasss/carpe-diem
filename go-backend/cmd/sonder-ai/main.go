package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"
)

// ---------- Request/Response DTOs ----------

type CityScoreRatingInput struct {
	AttractionName string `json:"attraction_name"`
	Category       string `json:"category"`
	Score          int    `json:"score"`
}

type CityScoreRequest struct {
	City     string                  `json:"city"`
	Country  string                  `json:"country"`
	Ratings  []CityScoreRatingInput `json:"ratings"`
}

type CityScoreResponse struct {
	CumulativeScore float64            `json:"cumulative_score"`
	ScoreBreakdown  map[string]float64 `json:"score_breakdown,omitempty"`
	Summary         string            `json:"summary"`
	Highlight       string            `json:"highlight"`
	WouldRecommendIf string          `json:"would_recommend_if"`
}

type RatedCityInput struct {
	City          string   `json:"city"`
	Score         float64  `json:"score"`
	TopCategories []string `json:"top_categories"`
	LowCategories []string `json:"low_categories"`
}

type TravelProfileRequest struct {
	RatedCities []RatedCityInput `json:"rated_cities"`
}

type RecommendationItem struct {
	Destination string   `json:"destination"`
	MatchReason string   `json:"match_reason"`
	VibeTags    []string `json:"vibe_tags"`
	MatchScore  float64  `json:"match_score"`
}

type TravelProfileResponse struct {
	PersonalityType        string               `json:"personality_type"`
	PersonalityDescription string              `json:"personality_description"`
	TasteTraits            []string            `json:"taste_traits"`
	Recommendations         []RecommendationItem `json:"recommendations"`
}

// ---------- Gemini client ----------

type GeminiPart struct {
	Text string `json:"text"`
}

type GeminiContent struct {
	Role  string       `json:"role"`
	Parts []GeminiPart `json:"parts"`
}

type GeminiRequest struct {
	Contents []GeminiContent `json:"contents"`
}

type GeminiResponse struct {
	Candidates []struct {
		Content struct {
			Parts []GeminiPart `json:"parts"`
		} `json:"content"`
	} `json:"candidates"`
}

type Server struct {
	httpClient *http.Client
	geminiAPIKey string
}

func main() {
	geminiKey := strings.TrimSpace(os.Getenv("GEMINI_API_KEY"))
	if geminiKey == "" {
		panic("missing GEMINI_API_KEY env var")
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	s := &Server{
		httpClient: &http.Client{Timeout: 60 * time.Second},
		geminiAPIKey: geminiKey,
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/api/city-score", s.handleCityScore)
	mux.HandleFunc("/api/travel-profile", s.handleTravelProfile)

	fmt.Printf("sonder-ai listening on :%s\n", port)
	if err := http.ListenAndServe(":"+port, mux); err != nil {
		panic(err)
	}
}

func (s *Server) handleCityScore(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req CityScoreRequest
	if err := json.NewDecoder(io.LimitReader(r.Body, 1<<20)).Decode(&req); err != nil {
		http.Error(w, "bad request json", http.StatusBadRequest)
		return
	}
	if req.City == "" || req.Country == "" {
		http.Error(w, "city and country are required", http.StatusBadRequest)
		return
	}

	resp, err := s.generateCityScore(r.Context(), req)
	if err != nil {
		http.Error(w, "AI generation failed: "+err.Error(), http.StatusInternalServerError)
		return
	}

	writeJSON(w, resp)
}

func (s *Server) handleTravelProfile(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req TravelProfileRequest
	if err := json.NewDecoder(io.LimitReader(r.Body, 1<<20)).Decode(&req); err != nil {
		http.Error(w, "bad request json", http.StatusBadRequest)
		return
	}
	if len(req.RatedCities) == 0 {
		http.Error(w, "rated_cities is required", http.StatusBadRequest)
		return
	}

	resp, err := s.generateTravelProfile(r.Context(), req)
	if err != nil {
		http.Error(w, "AI generation failed: "+err.Error(), http.StatusInternalServerError)
		return
	}

	writeJSON(w, resp)
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	enc := json.NewEncoder(w)
	enc.SetIndent("", "  ")
	_ = enc.Encode(v)
}

func (s *Server) generateCityScore(ctx context.Context, req CityScoreRequest) (CityScoreResponse, error) {
	lines := make([]string, 0, len(req.Ratings))
	for _, rr := range req.Ratings {
		lines = append(lines, fmt.Sprintf("%s: %s — %d/5 stars", rr.Category, rr.AttractionName, rr.Score))
	}

	userText := fmt.Sprintf(
		`The user visited %s, %s and rated the following attractions:
%s

Return JSON only with keys:
cumulative_score (0–10),
score_breakdown,
summary,
highlight,
would_recommend_if.`,
		req.City, req.Country, strings.Join(lines, "\n"),
	)

	systemPrompt := `You are a travel analyst. Given a user's attraction ratings for a city, calculate a weighted cumulative score (0–10) and write a personalized city summary. Respond with JSON only, no markdown or commentary.`

	text, err := s.callGemini(ctx, systemPrompt, userText)
	if err != nil {
		return CityScoreResponse{}, err
	}

	var out CityScoreResponse
	if err := json.Unmarshal(text, &out); err != nil {
		return CityScoreResponse{}, fmt.Errorf("invalid JSON from model: %w", err)
	}
	return out, nil
}

func (s *Server) generateTravelProfile(ctx context.Context, req TravelProfileRequest) (TravelProfileResponse, error) {
	lines := make([]string, 0, len(req.RatedCities))
	for _, c := range req.RatedCities {
		topJoined := strings.Join(c.TopCategories, ", ")
		lowJoined := strings.Join(c.LowCategories, ", ")
		lines = append(lines, fmt.Sprintf("%s: cumulative score %g, highest rated categories: %s, lowest rated: %s", c.City, c.Score, topJoined, lowJoined))
	}

	userText := fmt.Sprintf(
		`The user has rated attractions across the following cities:
%s

Return JSON only with keys:
personality_type,
personality_description,
taste_traits (5 items),
recommendations (array of { destination, match_reason, vibe_tags, match_score } with exactly 5 items).`,
		strings.Join(lines, "\n"),
	)

	systemPrompt := `You are a travel taste expert. Based on a user's attraction ratings across multiple cities, infer their travel personality. Respond with JSON only, no markdown or commentary.`

	text, err := s.callGemini(ctx, systemPrompt, userText)
	if err != nil {
		return TravelProfileResponse{}, err
	}

	var out TravelProfileResponse
	if err := json.Unmarshal(text, &out); err != nil {
		return TravelProfileResponse{}, fmt.Errorf("invalid JSON from model: %w", err)
	}
	return out, nil
}

func (s *Server) callGemini(ctx context.Context, systemPrompt, userText string) ([]byte, error) {
	combined := systemPrompt + "\n\n" + userText

	type reqBody struct {
		Contents []GeminiContent `json:"contents"`
	}

	body := reqBody{
		Contents: []GeminiContent{
			{
				Role: "user",
				Parts: []GeminiPart{
					{Text: combined},
				},
			},
		},
	}

	b, _ := json.Marshal(body)

	url := fmt.Sprintf("https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=%s", s.geminiAPIKey)
	httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(b))
	if err != nil {
		return nil, err
	}
	httpReq.Header.Set("Content-Type", "application/json")

	res, err := s.httpClient.Do(httpReq)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()

	respBytes, _ := io.ReadAll(res.Body)
	if res.StatusCode < 200 || res.StatusCode >= 300 {
		return nil, fmt.Errorf("gemini http %d: %s", res.StatusCode, string(respBytes))
	}

	var gr GeminiResponse
	if err := json.Unmarshal(respBytes, &gr); err != nil {
		return nil, fmt.Errorf("could not parse gemini response: %w", err)
	}
	if len(gr.Candidates) == 0 || len(gr.Candidates[0].Content.Parts) == 0 {
		return nil, errors.New("gemini: empty candidates/content")
	}

	text := gr.Candidates[0].Content.Parts[0].Text
	if strings.TrimSpace(text) == "" {
		return nil, errors.New("gemini: empty text")
	}

	clean := stripCodeFences(text)
	return []byte(clean), nil
}

func stripCodeFences(s string) string {
	trim := strings.TrimSpace(s)
	trim = strings.ReplaceAll(trim, "```json", "")
	trim = strings.ReplaceAll(trim, "```", "")
	return strings.TrimSpace(trim)
}

