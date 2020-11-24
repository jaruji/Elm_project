import { group, sleep } from 'k6';
import http from 'k6/http';

// Version: 1.2
// Creator: WebInspector

export let options = {
	maxRedirects: 0,
	stages: [
	{
		target : 20, duration : "10s"
	},
	]
};

export default function() {

	group("page_13 - http://localhost:8000/", function() {
		let req, res;
		req = [{
			"method": "put",
			"url": "http://localhost:3000/upload/image",
			"params": {
				"headers": {
					"Host": "localhost:3000",
					"Connection": "keep-alive",
					"name": "Screenshot from 2020-11-19 17-46-52.png",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"auth": "75b521307b96217bddcdf648f13b38c60191fa82dc1e3359e3c0d034b5285e88e4d39a2730cb75f4b8269221338704dd",
					"Content-Type": "image/png",
					"Accept": "*/*",
					"Origin": "http://localhost:8000",
					"Sec-Fetch-Site": "same-site",
					"Sec-Fetch-Mode": "cors",
					"Sec-Fetch-Dest": "empty",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			},
			"body": "/home/ramang/Developer/Elm_project/server/data/img/f898b05f61a4ac51400b.png"
		},{
			"method": "options",
			"url": "http://localhost:3000/upload/image",
			"body": "/home/ramang/Developer/Elm_project/server/data/img/f898b05f61a4ac51400b.png",
			"params": {
				"headers": {
					"Host": "localhost:3000",
					"Connection": "keep-alive",
					"Accept": "*/*",
					"Access-Control-Request-Method": "PUT",
					"Access-Control-Request-Headers": "auth,content-type,name",
					"Origin": "http://localhost:8000",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"Sec-Fetch-Mode": "cors",
					"Sec-Fetch-Site": "same-site",
					"Sec-Fetch-Dest": "empty",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		},{
			"method": "post",
			"url": "http://localhost:3000/upload/metadata",
			"body": "{\"title\":\"aaa\",\"tags\":[],\"description\":\"\",\"id\":\"6201282c35d2cec327ec\"}",
			"params": {
				"headers": {
					"Host": "localhost:3000",
					"Connection": "keep-alive",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"auth": "75b521307b96217bddcdf648f13b38c60191fa82dc1e3359e3c0d034b5285e88e4d39a2730cb75f4b8269221338704dd",
					"Content-Type": "application/json",
					"Accept": "*/*",
					"Origin": "http://localhost:8000",
					"Sec-Fetch-Site": "same-site",
					"Sec-Fetch-Mode": "cors",
					"Sec-Fetch-Dest": "empty",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		},{
			"method": "options",
			"url": "http://localhost:3000/upload/metadata",
			"params": {
				"headers": {
					"Host": "localhost:3000",
					"Connection": "keep-alive",
					"Accept": "*/*",
					"Access-Control-Request-Method": "POST",
					"Access-Control-Request-Headers": "auth,content-type",
					"Origin": "http://localhost:8000",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"Sec-Fetch-Mode": "cors",
					"Sec-Fetch-Site": "same-site",
					"Sec-Fetch-Dest": "empty",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		},{
			"method": "get",
			"url": "http://localhost:3000/comment/get?id=6201282c35d2cec327ec",
			"params": {
				"headers": {
					"Host": "localhost:3000",
					"Connection": "keep-alive",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"Accept": "*/*",
					"Origin": "http://localhost:8000",
					"Sec-Fetch-Site": "same-site",
					"Sec-Fetch-Mode": "cors",
					"Sec-Fetch-Dest": "empty",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		},{
			"method": "get",
			"url": "http://localhost:3000/image/info?id=6201282c35d2cec327ec",
			"params": {
				"headers": {
					"Host": "localhost:3000",
					"Connection": "keep-alive",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"auth": "75b521307b96217bddcdf648f13b38c60191fa82dc1e3359e3c0d034b5285e88e4d39a2730cb75f4b8269221338704dd",
					"Accept": "*/*",
					"Origin": "http://localhost:8000",
					"Sec-Fetch-Site": "same-site",
					"Sec-Fetch-Mode": "cors",
					"Sec-Fetch-Dest": "empty",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		},{
			"method": "get",
			"url": "http://localhost:3000/image?id=6201282c35d2cec327ec",
			"params": {
				"headers": {
					"Host": "localhost:3000",
					"Connection": "keep-alive",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"Accept": "*/*",
					"Origin": "http://localhost:8000",
					"Sec-Fetch-Site": "same-site",
					"Sec-Fetch-Mode": "cors",
					"Sec-Fetch-Dest": "empty",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		},{
			"method": "options",
			"url": "http://localhost:3000/image/info?id=6201282c35d2cec327ec",
			"params": {
				"headers": {
					"Host": "localhost:3000",
					"Connection": "keep-alive",
					"Accept": "*/*",
					"Access-Control-Request-Method": "GET",
					"Access-Control-Request-Headers": "auth",
					"Origin": "http://localhost:8000",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"Sec-Fetch-Mode": "cors",
					"Sec-Fetch-Site": "same-site",
					"Sec-Fetch-Dest": "empty",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		},{
			"method": "get",
			"url": "http://localhost:3000/image/stats?id=6201282c35d2cec327ec",
			"params": {
				"headers": {
					"Host": "localhost:3000",
					"Connection": "keep-alive",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"Accept": "*/*",
					"Origin": "http://localhost:8000",
					"Sec-Fetch-Site": "same-site",
					"Sec-Fetch-Mode": "cors",
					"Sec-Fetch-Dest": "empty",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		},{
			"method": "get",
			"url": "http://localhost:3000/img/6201282c35d2cec327ec.png",
			"params": {
				"cookies": {
					"_xsrf": "2|2cc5408e|f76029467d1172bb5dd33477e29116eb|1603817820",
					"username-localhost-8888": "\"2|1:0|10:1603818377|23:username-localhost-8888|44:NTRiYWU0ZDgyM2FiNDAzZDg2ZGFkYTY2ZjlmMmQ3ZjE=|719bd69cb58425507e0e75377d2a934aa883aad7db87998535116b5f6407e7d0\""
				},
				"headers": {
					"Host": "localhost:3000",
					"Connection": "keep-alive",
					"User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36",
					"Accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
					"Sec-Fetch-Site": "same-site",
					"Sec-Fetch-Mode": "no-cors",
					"Sec-Fetch-Dest": "image",
					"Referer": "http://localhost:8000/",
					"Accept-Encoding": "gzip, deflate, br",
					"Accept-Language": "en-US,en;q=0.9"
				}
			}
		}];
		res = http.batch(req);
		// Random sleep between 20s and 40s
		sleep(Math.floor(Math.random()*20+20));
	});

}
