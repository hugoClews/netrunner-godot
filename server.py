#!/usr/bin/env python3
"""
HTTP server with CORS headers for Godot 4 web exports.
Required headers for SharedArrayBuffer support.
"""

import http.server
import socketserver
import os

PORT = 8889
DIRECTORY = "build"

class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)
    
    def end_headers(self):
        # Required for Godot 4 web exports with threading
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

if __name__ == "__main__":
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    
    with ReusableTCPServer(("", PORT), CORSRequestHandler) as httpd:
        print(f"Serving Godot export at http://0.0.0.0:{PORT}")
        print("Headers: COOP + COEP enabled for SharedArrayBuffer")
        httpd.serve_forever()
