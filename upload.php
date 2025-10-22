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

// Function to search images using SerpAPI (Google Images)
function search_google_images($query) {
    $api_key = '60a84e87f8cb7e738d8147165cdcd5cd732d0ff5fd97af5f244b02ae04b9eb97';
    $url = "https://serpapi.com/search.json?engine=google_images&q=" . urlencode($query) . "&api_key=" . $api_key;
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    $response = curl_exec($ch);
    curl_close($ch);
    $data = json_decode($response, true);
    $images = [];
    if (isset($data['images_results'])) {
        foreach (array_slice($data['images_results'], 0, 10) as $img) {
            $images[] = $img['original'];
        }
    }
    return $images;
}

// Handle search
$images = [];
$nama_produk = "";
if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST["search_nama_barang"])) {
    $nama_barang = $_POST["search_nama_barang"];
    $sql = "SELECT kode_barang FROM produk WHERE nama_produk = '$nama_barang'";
    $result = $conn->query($sql);
    if ($result->num_rows > 0) {
        $row = $result->fetch_assoc();
        $kode_barang = $row['kode_barang'];
        $nama_produk = $nama_barang;
        $query = str_replace('-', ' ', $nama_produk);
        $images = search_google_images($query);
    } else {
        echo "<script>alert('Nama barang tidak ada dalam data');</script>";
    }
}

// Handle upload selected images
if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST["upload_selected"]) && isset($_POST["selected_images"]) && isset($_POST["kode_barang_update"])) {
    $selected_images = $_POST["selected_images"];
    $kode_barang = $_POST["kode_barang_update"];

    $target_dir = "assets/image/";
    $uploaded_paths = [];

    foreach ($selected_images as $image_url) {
        $filename = basename(parse_url($image_url, PHP_URL_PATH));
        if (!$filename) {
            $filename = $kode_barang . "_" . uniqid() . ".jpg";
        }
        $target_file = $target_dir . $filename;

        $ch = curl_init($image_url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
        $image_data = curl_exec($ch);
        curl_close($ch);

        if ($image_data) {
            file_put_contents($target_file, $image_data);
            $uploaded_paths[] = $target_file;
        } else {
            echo "<script>alert('Gagal mendownload gambar: $image_url');</script>";
        }
    }

    if (!empty($uploaded_paths)) {
        // Update gambar field in database as JSON array
        $image_paths_json = json_encode($uploaded_paths);
        $sql = "UPDATE produk SET gambar = '$image_paths_json' WHERE kode_barang = '$kode_barang'";
        if ($conn->query($sql) === TRUE) {
            echo "<script>alert('Gambar berhasil diupload dan diupdate');</script>";
        } else {
            echo "Error: " . $sql . "<br>" . $conn->error;
        }
    }
}

// Check if form is submitted for manual upload
if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_FILES["images"]) && isset($_POST["kode_barang"])) {
    $kode_barang = $_POST["kode_barang"];

    // Check if kode_barang exists
    $check_sql = "SELECT id FROM produk WHERE kode_barang = '$kode_barang'";
    $result = $conn->query($check_sql);

    if ($result->num_rows > 0) {
        $target_dir = "assets/image/";
        $uploaded_paths = [];

        foreach ($_FILES["images"]["name"] as $key => $name) {
            $target_file = $target_dir . basename($name);
            $uploadOk = 1;
            $imageFileType = strtolower(pathinfo($target_file, PATHINFO_EXTENSION));

            // Check if image file is a actual image or fake image
            $check = getimagesize($_FILES["images"]["tmp_name"][$key]);
            if ($check !== false) {
                $uploadOk = 1;
            } else {
                echo "File $name is not an image.";
                $uploadOk = 0;
            }

            // Check if file already exists
            if (file_exists($target_file)) {
                echo "Sorry, file $name already exists.";
                $uploadOk = 0;
            }

            // Check file size
            if ($_FILES["images"]["size"][$key] > 500000) {
                echo "Sorry, file $name is too large.";
                $uploadOk = 0;
            }

            // Allow certain file formats
            if ($imageFileType != "jpg" && $imageFileType != "png" && $imageFileType != "jpeg" && $imageFileType != "gif") {
                echo "Sorry, only JPG, JPEG, PNG & GIF files are allowed for $name.";
                $uploadOk = 0;
            }

            if ($uploadOk == 1) {
                if (move_uploaded_file($_FILES["images"]["tmp_name"][$key], $target_file)) {
                    $uploaded_paths[] = $target_file;
                } else {
                    echo "Sorry, there was an error uploading $name.";
                }
            }
        }

        if (!empty($uploaded_paths)) {
            // Update gambar field in database as JSON array
            $image_paths_json = json_encode($uploaded_paths);
            $sql = "UPDATE produk SET gambar = '$image_paths_json' WHERE kode_barang = '$kode_barang'";
            if ($conn->query($sql) === TRUE) {
                echo "Files have been uploaded and updated in database.";
            } else {
                echo "Error: " . $sql . "<br>" . $conn->error;
            }
        }
    } else {
        echo "<script>alert('Kode barang tidak ada dalam data');</script>";
    }
}

$conn->close();
?>

<!DOCTYPE html>
<html>
<head>
    <title>Upload Image</title>
</head>
<body>
    <h2>Search and Update Image</h2>
    <form action="" method="post">
        Nama Barang untuk Search:
        <input type="text" name="search_nama_barang" required><br><br>
        <input type="submit" value="Search Images">
    </form>

    <?php if (!empty($images)): ?>
        <h3>Gambar untuk produk: <?php echo htmlspecialchars($nama_produk); ?></h3>
        <form action="" method="post">
            <div style="display: flex; flex-wrap: wrap;">
                <?php foreach ($images as $index => $image_url): ?>
                    <div style="margin: 10px;">
                        <img src="<?php echo htmlspecialchars($image_url); ?>" alt="Image" style="width: 200px; height: 200px; object-fit: cover;"><br>
                        <input type="checkbox" name="selected_images[]" value="<?php echo htmlspecialchars($image_url); ?>" id="img_<?php echo $index; ?>">
                        <label for="img_<?php echo $index; ?>">Select</label>
                    </div>
                <?php endforeach; ?>
            </div>
            Kode Barang untuk Update:
            <input type="text" name="kode_barang_update" required><br><br>
            <input type="submit" name="upload_selected" value="Upload Selected Images">
        </form>
    <?php endif; ?>
</body>
</html>
