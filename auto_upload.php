<?php
// Database connection
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "azzahra2_multibrand";

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Normalisasi nama produk agar lebih umum untuk pencarian gambar
function normalize_query($name) {
    $name = strtoupper($name);

    if (strpos($name, 'HP') === 0) {
        $brand = 'HP';
    } elseif (strpos($name, 'ASUS') === 0 || strpos($name, 'A') === 0 || strpos($name, 'E') === 0) {
        $brand = 'ASUS';
    } elseif (strpos($name, 'LENOVO') === 0) {
        $brand = 'LENOVO';
    } else {
        $brand = '';
    }

    // Seri dasar (bisa kamu tambahkan sesuai kebutuhan)
    if (strpos($name, 'E1404') !== false || strpos($name, 'A1404') !== false) {
        $series = 'Vivobook 14';
    } elseif (strpos($name, 'DQ5') !== false) {
        $series = 'HP 14';
    } elseif (strpos($name, 'VIPS') !== false) {
        $series = 'ASUS OLED 14';
    } elseif (strpos($name, 'IDEAPAD') !== false) {
        $series = 'IdeaPad 3';
    } else {
        $series = 'laptop';
    }

    return trim("$brand $series");
}

// Function to search images using SerpAPI (Google Images)
function search_google_images($query) {
    $api_key = '60a84e87f8cb7e738d8147165cdcd5cd732d0ff5fd97af5f244b02ae04b9eb97';
    $queries = [
        $query,
        str_replace('-', ' ', $query),
        normalize_query($query)
    ];

    foreach ($queries as $q) {
        $url = "https://serpapi.com/search.json?engine=google_images&q=" . urlencode($q)
             . "&google_domain=google.co.id&gl=id&hl=id&safe=off&api_key=" . $api_key;

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
        $response = curl_exec($ch);
        curl_close($ch);

        $data = json_decode($response, true);
        $images = [];
        if (isset($data['images_results'])) {
            foreach (array_slice($data['images_results'], 0, 3) as $img) {
                if (isset($img['original'])) {
                    $images[] = $img['original'];
                }
            }
        }

        if (!empty($images)) {
            echo "✅ Found " . count($images) . " images for query: $q<br>";
            return $images;
        } else {
            echo "⚠️ No images found for query: $q<br>";
        }
    }

    return [];
}

// Ambil produk yang belum punya gambar
$sql = "SELECT kode_barang, nama_produk FROM produk WHERE gambar IS NULL OR gambar = '' LIMIT 10";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    set_time_limit(0);

    while ($row = $result->fetch_assoc()) {
        $kode_barang = $row['kode_barang'];
        $nama_produk = $row['nama_produk'];
        $images = search_google_images($nama_produk);

        if (!empty($images)) {
            $target_dir = "assets/image/";
            $uploaded_paths = [];

            foreach ($images as $image_url) {
                if (!empty($image_url)) {
                    $filename = basename(parse_url($image_url, PHP_URL_PATH));
                    if (!$filename) $filename = $kode_barang . "_" . uniqid() . ".jpg";
                    $target_file = $target_dir . $filename;

                    $ch = curl_init($image_url);
                    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
                    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
                    $image_data = curl_exec($ch);
                    curl_close($ch);

                    if ($image_data) {
                        file_put_contents($target_file, $image_data);
                        $uploaded_paths[] = $target_file;
                    }
                }
            }

            if (!empty($uploaded_paths)) {
                $image_paths_json = $conn->real_escape_string(json_encode($uploaded_paths));
                $update_sql = "UPDATE produk SET gambar = '$image_paths_json' WHERE kode_barang = '$kode_barang'";
                if ($conn->query($update_sql) === TRUE) {
                    echo "🖼️ Updated $kode_barang with " . count($uploaded_paths) . " images.<br>";
                } else {
                    echo "❌ Error updating $kode_barang: " . $conn->error . "<br>";
                }
            }
        } else {
            echo "❌ No images found for $nama_produk.<br>";
        }

        flush();
        ob_flush();
    }
} else {
    echo "No products without images found.";
}

$conn->close();
?>
