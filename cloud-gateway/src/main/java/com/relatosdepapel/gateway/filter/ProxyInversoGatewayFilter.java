package com.relatosdepapel.gateway.filter;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.relatosdepapel.gateway.dto.ProxyInversoRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.Ordered;
import org.springframework.core.io.buffer.DataBuffer;
import org.springframework.core.io.buffer.DataBufferUtils;
import org.springframework.core.io.buffer.DefaultDataBufferFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.server.RequestPath;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.http.server.reactive.ServerHttpRequestDecorator;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.List;

/**
 * Gateway filter that implements the Proxy Inverso pattern.
 * Transcribes POST requests with { "method", "path", "body"? } into the actual HTTP method and path.
 * <p>
 * Example: POST /api/books/action with body {"method":"GET","path":"/api/books/123"}
 * becomes GET /api/books/123 forwarded to ms-books-catalogue.
 */
@Component
public class ProxyInversoGatewayFilter implements org.springframework.cloud.gateway.filter.GlobalFilter, Ordered {

    private static final Logger log = LoggerFactory.getLogger(ProxyInversoGatewayFilter.class);
    private static final List<String> PROXY_ACTION_PATHS = Arrays.asList(
            "/api/books/action",
            "/api/payments/action"
    );

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final DefaultDataBufferFactory dataBufferFactory = new DefaultDataBufferFactory();

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, org.springframework.cloud.gateway.filter.GatewayFilterChain chain) {
        String path = exchange.getRequest().getPath().value();

        if (!PROXY_ACTION_PATHS.contains(path)) {
            return chain.filter(exchange);
        }

        return DataBufferUtils.join(exchange.getRequest().getBody())
                .switchIfEmpty(Mono.error(new IllegalStateException("Proxy Inverso requires a request body")))
                .flatMap(dataBuffer -> {
                    byte[] bytes = new byte[dataBuffer.readableByteCount()];
                    dataBuffer.read(bytes);
                    DataBufferUtils.release(dataBuffer);

                    try {
                        String json = new String(bytes, StandardCharsets.UTF_8);
                        ProxyInversoRequest parsed = objectMapper.readValue(json, ProxyInversoRequest.class);

                        if (parsed.getMethod() == null || parsed.getPath() == null) {
                            return Mono.error(new IllegalArgumentException("Proxy Inverso requires 'method' and 'path' in request body"));
                        }

                        HttpMethod httpMethod = HttpMethod.valueOf(parsed.getMethod().toUpperCase());

                        ServerHttpRequest newRequest = buildRequest(exchange.getRequest(), parsed, httpMethod);
                        ServerWebExchange mutatedExchange = exchange.mutate().request(newRequest).build();

                        log.debug("Proxy Inverso: {} {} -> {} {}", exchange.getRequest().getMethod(), path,
                                httpMethod, parsed.getPath());

                        return chain.filter(mutatedExchange);
                    } catch (Exception e) {
                        log.error("Proxy Inverso parse error: {}", e.getMessage());
                        return Mono.error(e);
                    }
                });
    }

    private ServerHttpRequest buildRequest(ServerHttpRequest original, ProxyInversoRequest parsed, HttpMethod httpMethod) {
        boolean noBody = parsed.getBody() == null || HttpMethod.GET.equals(httpMethod) || HttpMethod.DELETE.equals(httpMethod);

        return new ServerHttpRequestDecorator(original) {
            @Override
            public HttpMethod getMethod() {
                return httpMethod;
            }

            @Override
            public RequestPath getPath() {
                return RequestPath.parse(parsed.getPath(), "");
            }

            @Override
            public URI getURI() {
                URI originalUri = original.getURI();
                return URI.create(originalUri.getScheme() + "://" + originalUri.getHost()
                        + (originalUri.getPort() > 0 ? ":" + originalUri.getPort() : "")
                        + (parsed.getPath().startsWith("/") ? parsed.getPath() : "/" + parsed.getPath())
                        + (originalUri.getQuery() != null ? "?" + originalUri.getQuery() : ""));
            }

            @Override
            public HttpHeaders getHeaders() {
                HttpHeaders headers = new HttpHeaders();
                headers.addAll(original.getHeaders());
                if (noBody) {
                    headers.remove(HttpHeaders.CONTENT_LENGTH);
                    headers.remove(HttpHeaders.CONTENT_TYPE);
                } else {
                    try {
                        byte[] bodyBytes = objectMapper.writeValueAsBytes(parsed.getBody());
                        headers.setContentLength(bodyBytes.length);
                        headers.setContentType(MediaType.APPLICATION_JSON);
                    } catch (Exception ignored) { }
                }
                return headers;
            }

            @Override
            public Flux<DataBuffer> getBody() {
                if (noBody) {
                    return Flux.empty();
                }
                try {
                    byte[] bodyBytes = objectMapper.writeValueAsBytes(parsed.getBody());
                    return Flux.just(dataBufferFactory.wrap(bodyBytes));
                } catch (Exception e) {
                    return Flux.error(e);
                }
            }
        };
    }

    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE;
    }
}
