package com.canbus.controller;

import com.canbus.model.CanFrame;
import com.canbus.service.CanService;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
@CrossOrigin(origins = "*")
public class CanController {

    private final CanService canService;
    private int totalFrameCount = 0;

    public CanController(CanService canService) {
        this.canService = canService;
    }

    /**
     * GET /api/frames - return mock CAN frame list
     */
    @GetMapping("/frames")
    public List<CanFrame> getFrames() {
        List<CanFrame> frames = canService.generateMockFrames();
        totalFrameCount += frames.size();
        return frames;
    }

    /**
     * POST /api/dbc/parse - accept DBC text, return parsed messages
     */
    @PostMapping("/dbc/parse")
    public Map<String, Object> parseDbc(@RequestBody String dbcText) {
        return canService.parseDbc(dbcText);
    }

    /**
     * GET /api/stats - return bus statistics
     */
    @GetMapping("/stats")
    public Map<String, Object> getStats() {
        return canService.getStats(totalFrameCount);
    }
}
