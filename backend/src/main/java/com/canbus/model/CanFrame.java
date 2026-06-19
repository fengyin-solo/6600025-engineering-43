package com.canbus.model;

import java.util.Map;

public class CanFrame {
    private String id;
    private long timestamp;
    private int arbitrationId;
    private int dlc;
    private String data;
    private Map<String, Double> decoded;
    private String direction;

    public CanFrame() {}

    public CanFrame(String id, long timestamp, int arbitrationId, int dlc,
                    String data, Map<String, Double> decoded, String direction) {
        this.id = id;
        this.timestamp = timestamp;
        this.arbitrationId = arbitrationId;
        this.dlc = dlc;
        this.data = data;
        this.decoded = decoded;
        this.direction = direction;
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public long getTimestamp() { return timestamp; }
    public void setTimestamp(long timestamp) { this.timestamp = timestamp; }

    public int getArbitrationId() { return arbitrationId; }
    public void setArbitrationId(int arbitrationId) { this.arbitrationId = arbitrationId; }

    public int getDlc() { return dlc; }
    public void setDlc(int dlc) { this.dlc = dlc; }

    public String getData() { return data; }
    public void setData(String data) { this.data = data; }

    public Map<String, Double> getDecoded() { return decoded; }
    public void setDecoded(Map<String, Double> decoded) { this.decoded = decoded; }

    public String getDirection() { return direction; }
    public void setDirection(String direction) { this.direction = direction; }
}
