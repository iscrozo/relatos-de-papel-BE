package com.relatosdepapel.gateway.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

/**
 * DTO for the Proxy Inverso pattern.
 * Client sends POST with this structure to transcribe to the actual HTTP method/path.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class ProxyInversoRequest {

    private String method;
    private String path;
    private Object body;

    public ProxyInversoRequest() {
    }

    public ProxyInversoRequest(String method, String path, Object body) {
        this.method = method;
        this.path = path;
        this.body = body;
    }

    public String getMethod() {
        return method;
    }

    public void setMethod(String method) {
        this.method = method;
    }

    public String getPath() {
        return path;
    }

    public void setPath(String path) {
        this.path = path;
    }

    public Object getBody() {
        return body;
    }

    public void setBody(Object body) {
        this.body = body;
    }
}
